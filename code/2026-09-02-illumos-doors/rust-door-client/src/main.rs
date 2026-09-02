use doors::Client;
use std::ffi::CStr;

fn main() {
    let client = Client::open("../my-file.door").unwrap();

    let input = b"Hello From Rust!!\0";
    let response = client.call_with_data(input).unwrap();
    let data = response.data();

    let c_str = CStr::from_bytes_with_nul(data).unwrap();
    let s = c_str.to_string_lossy();

    println!("got data: {}", s);
}
