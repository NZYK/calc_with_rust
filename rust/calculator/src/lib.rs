fn primes(num: usize) -> Vec<usize> {
    if num < 2 {
        return vec![];
    }
    let mut primes: Vec<bool> = vec![true; num + 1];
    primes[0] = false;
    primes[1] = false;

    let limit: usize = (num as f64).sqrt() as usize;
    for i in 2..=limit {
        if primes[i] {
            for j in (i * i..=num).step_by(i) {
                primes[j] = false;
            }
        }
    }
    primes
        .iter()
        .enumerate()
        .filter_map(|(i, &is_prime)| if is_prime { Some(i) } else { None })
        .collect()
}

#[unsafe(no_mangle)]
pub extern "C" fn calc_primes(num: usize, out_len: *mut usize) -> *mut usize {
    let primes: Vec<usize> = primes(num);
    let len: usize = primes.len();
    // out_lenがNULLでない場合に要素数を書き込む
    unsafe {
        if !out_len.is_null() {
            *out_len = len;
        }
    }
    let mut boxed_primes: Box<[usize]> = primes.into_boxed_slice();
    let ptr: *mut usize = boxed_primes.as_mut_ptr();
    // 所有権を放棄
    std::mem::forget(boxed_primes);
    ptr
}

#[unsafe(no_mangle)]
pub extern "C" fn free_primes_array(ptr: *mut usize, len: usize) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        // Boxを再構築してdropさせることでメモリを解放する
        let _ = Box::from_raw(std::slice::from_raw_parts_mut(ptr, len));
    }
}
