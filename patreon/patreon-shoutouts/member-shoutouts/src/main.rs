//! Parse a Patreon CSV file and output the member names on the CLI

use std::io;

use anyhow::Result;
use serde::Deserialize;

const LINK: &str = "https://ysap.sh/patreon";
const TIERS: &[(&str, u32)] = &[
    // name, color (ANSI 256)
    ("/usr/bin/env bash", 162),
    ("/bin/bash", 167),
    ("/bin/sh", 179),
];
const COLUMNS: usize = 3;
const WIDTH: usize = 25;

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct Member {
    #[serde(rename = "Name")]
    pub name: String,
    #[serde(rename = "Email")]
    pub email: String,
    #[serde(rename = "Discord")]
    pub discord: Option<String>,
    #[serde(rename = "Patron Status")]
    pub patron_status: Option<String>,
    #[serde(rename = "Lifetime Amount")]
    pub lifetime_amount: Option<f64>,
    #[serde(rename = "Pledge Amount")]
    pub pledge_amount: Option<f64>,
    #[serde(rename = "Charge Frequency")]
    pub charge_frequency: Option<String>,
    #[serde(rename = "Tier")]
    pub tier: Option<String>,
    #[serde(rename = "Patronage Since Date")]
    pub patron_since: Option<String>,
    #[serde(rename = "Last Charge Date")]
    pub last_charge_date: Option<String>,
    #[serde(rename = "Last Charge Status")]
    pub last_charge_status: Option<String>,
    #[serde(rename = "User ID")]
    pub user_id: Option<u64>,
    #[serde(rename = "Additional Details")]
    pub additional_details: Option<String>,
}

impl Member {
    pub fn is_active(&self) -> bool {
        self.patron_status.as_deref() == Some("Active patron")
    }

    pub fn name(&self) -> String {
        match &self.additional_details {
            Some(s) => s.into(),
            None => self.name.clone(),
        }
    }
}

fn color256(n: u32) -> String {
    format!("\x1b[38;5;{}m", n)
}

const RST: &str = "\x1b[0m";
const DIM: &str = "\x1b[2m";

fn main() -> Result<()> {
    let mut rdr = csv::Reader::from_reader(io::stdin());
    let members: Vec<_> = rdr.deserialize::<Member>()
        .filter(Result::is_ok) // Not strictly necessary but prevents panics
        .map(Result::unwrap)
        .filter(Member::is_active)
        .collect();

    // sorted by most to least expensive
    fn print_tier(members: &Vec<Member>, tier: &str, color: u32){
        let tier_members: Vec<_> = members
            .iter()
            .filter(|m| m.tier.as_deref() == Some(tier))
            .collect();

        println!(
            "{}{}{} {}({} members){}",
            color256(color),
            tier,
            RST,
            DIM,
            tier_members.len(),
            RST);

        tier_members
            .iter()
            .enumerate()
            .map(|(i, member)| {
                match i % COLUMNS == COLUMNS - 1 {
                    true => println!("{}", member.name()),
                    false => print!("{:width$}", member.name(), width = WIDTH)
                }
            })
            .for_each(drop);

        println!();
        if tier_members.len() % COLUMNS != 0 {
            println!();
        }
    }

    TIERS
        .iter()
        .map(|(tier, color)| print_tier(&members, tier, *color))
        .for_each(drop);

    let total_recognized = members
        .iter()
        .filter(|m| {
            TIERS.iter().any(|(tier, _)| m.tier.as_deref() == Some(tier))
        })
        .count();

    println!("{}total: {} active members{}", DIM, total_recognized, RST);
    println!("{}patreon: {}{}{}{}", DIM, RST, color256(6), LINK, RST);

    Ok(())
}
