fn primes(num: u64) -> Vec<u64> {
    if num < 2 {
        return vec![];
    }
    let mut primes: Vec<bool> = vec![true; (num + 1) as usize];
    primes[0] = false;
    primes[1] = false;

    let limit: u64 = (num as f64).sqrt() as u64;
    for i in 2..=limit {
        if primes[i as usize] {
            for j in (i * i..=num).step_by(i as usize) {
                primes[j as usize] = false;
            }
        }
    }
    primes
        .iter()
        .enumerate()
        .filter_map(|(i, &is_prime)| if is_prime { Some(i as u64) } else { None })
        .collect()
}

#[unsafe(no_mangle)]
pub extern "C" fn calc_primes(num: u64, out_len: *mut usize) -> *mut u64 {
    let primes: Vec<u64> = primes(num);
    let len: usize = primes.len();
    // out_lenがNULLでない場合に要素数を書き込む
    unsafe {
        if !out_len.is_null() {
            *out_len = len;
        }
    }
    let mut boxed_primes: Box<[u64]> = primes.into_boxed_slice();
    let ptr: *mut u64 = boxed_primes.as_mut_ptr();
    // 所有権を放棄
    std::mem::forget(boxed_primes);
    ptr
}

#[unsafe(no_mangle)]
pub extern "C" fn free_primes_array(ptr: *mut u64, len: usize) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        // Boxを再構築してdropさせることでメモリを解放する
        let _ = Box::from_raw(std::slice::from_raw_parts_mut(ptr, len));
    }
}
