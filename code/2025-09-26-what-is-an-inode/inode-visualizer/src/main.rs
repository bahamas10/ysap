/*!
 * Convert a directory to a mermaid diagram
 *
 * Author: Dave Eddy <dave@daveeddy.com>
 * Date: September 12, 2025
 * License: MIT
 */

use std::collections::HashSet;
use std::env;
use std::fmt;
use std::fs;
use std::fs::{Metadata, read_dir, read_link, symlink_metadata};
use std::os::unix::fs::{FileTypeExt, MetadataExt};
use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use chrono::{TimeZone, Utc};
use clap::{Parser, ValueEnum};
use strmode::strmode;

/// Convert a directory to a mermaid diagram
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Direction to flow the graph
    #[arg(short, long, default_value_t, value_enum)]
    direction: Direction,

    /// Include '..' directories
    #[arg(long)]
    show_dot_dots: bool,

    /// Include '.' directories
    #[arg(long)]
    show_dots: bool,

    /// Directory to use as reference
    root: PathBuf,
}

/// Mermaid Class Diagram direction
#[derive(Debug, Default, Clone, ValueEnum)]
enum Direction {
    #[default]
    LR,
    RL,
    TB,
    BT,
}

impl fmt::Display for Direction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let s = match self {
            Self::LR => "LR",
            Self::RL => "RL",
            Self::TB => "TB",
            Self::BT => "BT",
        };
        write!(f, "{}", s)
    }
}

#[derive(Debug, Default)]
struct Cache {
    seen_inodes: HashSet<(u64, u64)>,
    seen_data: HashSet<String>,
    seen_dirs: HashSet<String>,
}

/// Convert a path to its basenmae (after canonicalization)
fn path_to_basename(p: &Path) -> Result<String> {
    Ok(fs::canonicalize(p)?
        .file_name()
        .unwrap_or_default()
        .to_string_lossy()
        .into_owned())
}

/// Return the filetype as a string given the stat object
fn filetype(metadata: &Metadata) -> &'static str {
    let ft = metadata.file_type();
    if ft.is_dir() {
        "directory"
    } else if ft.is_file() {
        "regular"
    } else if ft.is_symlink() {
        "symbolic link"
    } else if ft.is_socket() {
        "socket"
    } else if ft.is_fifo() {
        "fifo"
    } else if ft.is_block_device() {
        "block"
    } else if ft.is_char_device() {
        "char"
    } else {
        "unknown"
    }
}

/// Convert unix time to a simple timestamp format
fn fmt_date_ymd_utc(secs: i64) -> Result<String> {
    let dt = Utc.timestamp_opt(secs, 0).single().context("bad timestamp")?;
    Ok(dt.format("%Y-%m-%d %H:%M:%S").to_string())
}

/// Add commas to a number
fn format_with_commas(n: u64) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, c) in s.chars().rev().enumerate() {
        if i != 0 && i % 3 == 0 {
            out.push(',');
        }
        out.push(c);
    }
    out.chars().rev().collect()
}

/// Emit (if needed) the Inode class and a type-specific Data class, returning their IDs.
fn emit_inode_and_data(
    name: &str,
    md: &Metadata,
    path: &PathBuf,
    cache: &mut Cache,
) -> Result<String> {
    let ino = md.ino();
    let dev = md.dev();
    let nlink = md.nlink();
    let uid = md.uid();
    let gid = md.gid();
    let size = md.size();
    let atime = md.atime();
    let mtime = md.mtime();
    let ctime = md.ctime();

    let ftype = filetype(md);
    let mode_s = strmode(md.mode());

    // create unique and stable ideas
    let inode_key = (dev, ino);
    let inode_id = format!("Inode_{}_{}", dev, ino);
    let data_id = if md.is_dir() {
        format!("Dir_{}_{}", dev, ino)
    } else {
        format!("Data_{}_{}", dev, ino)
    };

    // Inode class (dedup by (dev, ino))
    if cache.seen_inodes.insert(inode_key) {
        // new inode - emit its class data

        println!("\tclass {} {{", inode_id);
        println!("\t\tinode: {}", ino);
        println!("\t\tdev: {}", dev);
        println!("\t\ttype: {}", ftype);
        println!("\t\tmode: {}", mode_s);
        println!("\t\tuid: {}", uid);
        println!("\t\tgid: {}", gid);
        if !md.is_dir() {
            println!("\t\tsize: {}", format_with_commas(size));
        }
        println!("\t\tnlink: {}", nlink);
        println!("\t\tmtime: {}", fmt_date_ymd_utc(mtime)?);
        println!("\t\tatime: {}", fmt_date_ymd_utc(atime)?);
        println!("\t\tctime: {}", fmt_date_ymd_utc(ctime)?);
        println!("\t\tstat(),lstat() `stat`");
        println!("\t}}");
    }

    // type-specific Data class
    if cache.seen_data.insert(data_id.clone()) {
        // new data - emit its class data

        if md.is_dir() {
            // do nothing - already handled
        } else if md.is_symlink() {
            println!("\tclass {} {{", data_id);
            let target = match read_link(path) {
                Ok(t) => t.to_string_lossy().to_string(),
                Err(_) => "<unreadable>".into(),
            };
            println!("\t\ttarget: {}", target);
            println!("\t\treadlink() `readlink`");
            println!("\t}}");
        } else {
            // regular/char/block/fifo/socket
            println!("\tclass {data_id} {{");
            println!("\t\tdata blocks for {}", name);
            println!("\t\tread() `cat`");
            println!("\t}}");
        }

        // link Inode -> Data
        println!("\t{inode_id} --> {data_id}");
    }

    Ok(inode_id)
}

/// Recursively process a real directory (no symlink following).
fn process_dir(
    args: &Args,
    dir: &Path,
    cache: &mut Cache,
    is_root: bool,
) -> Result<()> {
    let md = fs::metadata(dir)?;
    let ino = md.ino();
    let dev = md.dev();

    // get a list of entries in this dir
    let mut entries: Vec<(String, PathBuf)> = vec![];

    // should we add ".."? (never add ".." for the root dir)
    if args.show_dot_dots && !is_root {
        let parent_dir = dir
            .parent()
            .map(|d| d.to_path_buf())
            .unwrap_or_else(|| dir.to_path_buf());
        entries.push(("..".into(), parent_dir));
    }
    // should we add "."?
    if args.show_dots {
        let current_dir = dir.to_path_buf();
        entries.push((".".into(), current_dir));
    }
    // always add the rest of the entries from `readdir`
    for ent in read_dir(dir)? {
        let ent = ent?;
        let name = ent.file_name().to_string_lossy().into_owned();
        entries.push((name, ent.path()));
    }

    // emit Directory class for this dir (once)
    let dir_id = format!("Dir_{}_{}", dev, ino);
    if cache.seen_dirs.insert(dir_id.clone()) {
        // new dir found - make a class for it
        println!("\tclass {} {{", dir_id);
        println!("\t\t<<ls {}/>>", path_to_basename(dir)?);
        if is_root && args.show_dot_dots {
            // visually show ".." even if we are the root - just don't link it
            println!("\t\t..");
        }
        for (name, _) in &entries {
            println!("\t\t{}", name);
        }
        println!("\t\treaddir() `ls`");
        println!("\t}}");
    }

    // loop directory entries and recurse into them
    for (name, path) in &entries {
        let md = symlink_metadata(path)?;
        let inode_id = emit_inode_and_data(name, &md, path, cache)?;

        // Directory -> Inode edge labeled with entry name
        println!("\t{} --> {} : {}", dir_id, inode_id, name);

        // recurse into sub-directories (not symlink-to-dir nor "." or "..")
        if name != ".." && name != "." && md.is_dir() {
            process_dir(args, path, cache, false)?;
        }
    }

    Ok(())
}

/// Emit the mermaid header to stdout
fn emit_mermaid_header(args: &Args) {
    println!(
        r#"---
config:
  fontFamily: Monospace
  theme: mc
  layout: elk
  look: handDrawn
  wrap: false
---
classDiagram
direction {}"#,
        args.direction
    );
}

fn main() -> Result<()> {
    let args = Args::parse();

    // move into the directory to keep things simple
    env::set_current_dir(&args.root)?;

    let mut cache = Cache::default();
    emit_mermaid_header(&args);
    process_dir(&args, &PathBuf::from("."), &mut cache, true)?;

    Ok(())
}
