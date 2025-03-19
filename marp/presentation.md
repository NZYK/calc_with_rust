---
marp: true
---
# RubyとFFIを通じて見る他言語連携
発表者: 能津勇希

---
# 自己紹介
- 名前: 能津勇希（のづ ゆうき）
- 興味はどちらかというとバックエンド志向です
- 前回WebGLでGPGPUした人です

---

# 他言語連携って？
## 例えば、RubyのコードからRustの実行ファイルを呼んだりすること
![](./images/ruby_rust.png)

---

# 興味を持った背景
## pythonの有名なライブラリであるNumPyでは、速度のために内部実装がCやFortranで書かれていると聞いたことがある
![](./images/mark_arrow_down.png)
## 内部実装とはいうけど、言語が違うのにどうやってPythonから呼び出しているんだろう？


---

# 興味を持った背景
## ちょうどRustにも興味がある（よく使われているし、早いらしい）
![](./images/mark_arrow_down.png)
## Pythonと同じインタプリタ言語であるRubyで、Rustのコードを呼び出してみたい！

---

# 他言語連携の手法
- ## **サブプロセスの呼び出し**
- ## **FFI**　( **F**oreign **F**unction **I**nterface )

---

# 他言語連携の手法
## **サブプロセスの呼び出し**
Ruby→Nodeプロセスの例
```js
// adder.js
const a = Number(process.argv[2]);
const b = Number(process.argv[3]);
console.log(a + b);
```

```ruby
# main.rb
# システムコマンドと標準出力を介して値を受け取る
def add_by_node(a, b)
  result = (`node adder.js #{a} #{b}`.chomp).to_i
end
```
---

# 他言語連携の手法
## **サブプロセスの呼び出し**
## 標準入出力（やプロセス間通信）を使ってやりとりする手法
 - 感覚的にもとっつきやすい
 - 基本的に文字列でやり取りするため、値のハンドリングにシリアライズが必要
 - 別プロセスで実行される
 - 疎結合（メモリの共有なし）
 - => 柔軟で簡単だけど、パフォーマンスはよくない

---

# 他言語連携の手法
## **FFI**　( **F**oreign **F**unction **I**nterface )
 - CやC++など、バイナリ化されたライブラリをラップしてネイティブレベルで扱う
```ruby
# sample.dll には adderという関数が定義されていると仮定
require 'ffi'
module C
    extend FFI::Library
    ffi_lib File.join('sample.dll') # ファイルの読み込み
    # インターフェースのすり合わとラッパー関数の定義
    attach_function :adder, [:int :int], :pointer

    def self.add_by_bin(a, b)
        pointer = adder(a, b)
        pointer.read_int
    end
end
```
---

# 他言語連携の手法
## **FFI**　( **F**oreign **F**unction **I**nterface )
 - バイナリ化されたライブラリをロードし、その中の関数を呼び出す
 - 機械語になった関数を呼び出すために、コンパイルする側と、それを呼び出す側とで共通の約束に従っている必要がある。（関数の呼び方や、データ型のレイアウトやサイズなど）
 - ⇑ ABI(Application Binary Interface)と呼ばれる
 - 同一プロセスで、メモリも共有できる
 - オーバーヘッドが極小 + バイナリ実行のためパフォーマンスが高い

---

# 他言語連携の手法
## まとめ
| 手法 | プロセス | 値の授受 | パフォーマンス |
| ---- | ---- | ---- | ---- |
| サブプロセス | 別 | 標準入出力など | 低い |
| FFI | 同一 | メモリの共有（ポインタ使用） | 高い |
## 今回は内部実装としての他言語連携を行いたかったため、  
## FFIを選択

---

# なにをやるか
## Rustで指定した整数までの間の素数を列挙するライブラリを作成
 - ### primes(10) => [2, 3, 5, 7] （1~10までの素数を返す）
## RubyからFFIで呼び出す

---

# 実装
## アルゴリズムの紹介
### エラトステネスのふるい

1. 1 ~ n までを列挙して、全ての値が素数である（true)と仮定する。
`[{1: true},{2: true},{3: true},{4: true},{5: true},...,{n: true}]`
2. 1は素数ではないので偶数判定（FALSE）
`[{1: FALSE},{2: true},{3: true},{4: true},{5: true},...,{n: true}]`
3. 2は素数なので2から開始して、 2 * 2, 2 * 3 ... 2 * i >= n まで偶数判定していく
`[{1: FALSE},{2: true},{3: true},{4: FALSE},{5: true},{6: FALSE}...`
4. 続いて、3について同様の操作を行う（3 * 3, 3 * 4 ... をFALSEに）
5. 最後にtrueのままの値が素数になる

---

# 実装
## Rubyでの実装
```ruby
module Ruby
  def self.primes(n)
    return [] if n < 2

    # 素数判定用の配列を用意 初期値は全てtrue(素数と仮定)
    num_arr = Array.new(n + 1, true)
    # 0と1は素数ではないのでfalseにする
    num_arr[0] = num_arr[1] = false
    # ふるいにかける基準値はnの平方根まで。
    # 例えば　n=100の場合、10を素数と仮定した場合に10 * 10 からふるいにかけるが、このとき最初の値が範囲の最大値となるため。
    limit = Math.sqrt(n).to_i

    (2..limit).each do |i|
      next unless num_arr[i]
      # iがtrue(素数)の場合、iの倍数は素数ではないのでfalseにする。
      # i*2 ~ i*(i-1) まではすでにふるいにかけられているので i*i からスタート
      (i * i).step(n, i) { |j| num_arr[j] = false }
    end
    num_arr.each_index.select { |i| num_arr[i] }
  end
end
```

---

## Rustでの実装（primesを求める関数）
```rust
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
```
---

## Rustでの実装（ライブラリとしてエクスポートする関数）
ruby FFIは CのABIに対応しているので、extern "C" とすることでCのABIに準拠した形でビルドができる
```rust
#[unsafe(no_mangle)]
pub extern "C" fn calc_primes(num: u64, out_len: *mut usize) -> *mut u64 {
    let primes: Vec<u64> = primes(num);
    let len: usize = primes.len();
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
```
---
## Ruby FFIを使ったラッパーの実装
```ruby
module Rust
  require 'ffi'
  extend FFI::Library
  # ビルドしたライブラリのファイルパス
  ffi_lib CalcWithRust::RustLibConf::RUST_LIB_FILE_PATH
  attach_function :calc_primes, %i[uint64 pointer], :pointer
  attach_function :free_primes_array, %i[pointer uint64], :void

  def self.primes(n)
    out_len_ptr = FFI::MemoryPointer.new(:size_t) # ポインタをわたしてlengthを書き込んでもらう
    out_ptr = calc_primes(n, out_len_ptr)

    len = out_len_ptr.read_ulong # 書き込まれたlengthを読み出す
    primes_array = out_ptr.read_array_of_ulong(len) # 戻り値のポインタからArrayを読み出す

    free_primes_array(out_ptr, len) # 不要になったメモリを開放する
    primes_array
  end
end
```

---

# 実行結果
```ruby
require 'calc_with_rust'

p CalcWithRust::Ruby.primes(10)
# => [2, 3, 5, 7]

p CalcWithRust::Rust.primes(10)
# => [2, 3, 5, 7]
```

# できた！！！

---

# おまけ パフォーマンス計測
```ruby
require 'calc_with_rust'
require_relative 'action_analyzer.rb'
include ActionAnalyzer

last_num = 10000
times = 100

analyze_action 'Rubyコード' do
  times.times do
    CalcWithRust::Ruby.primes(last_num)
  end
end
analyze_action 'Rustコード' do
  times.times do
    CalcWithRust::Rust.primes(last_num)
  end
end
```

---
# パフォーマンス計測　結果
```
start 'Rubyコード'
end 'Rubyコード' (net: 67.023 ms, total: 67.023 ms)
start 'Rustコード'
end 'Rustコード' (net: 2.625 ms, total: 2.625 ms)
```
この条件だと25倍くらい早くなった。バイナリは早い・・・

---

# プロダクトにすることを考える
## たとえばgemとして配布するときのことを考える
- このgemはrustコードからビルドしたバイナリを使っている
- バイナリは環境依存のため、gemの中身に加えても例えばwindowsだと動かない...
  1. gemのインストール時に環境先でビルドしてもらう？
    - インストールのタイミングでcargoが必要。READMEとかにかけるが、bundlerでのインストールとは相性が悪そう
  2. 環境別にビルドしたバイナリをgemに含めておく？
    - CIの仕組みを作るなど管理が大変そう・・・

---

# プロダクトにすることを考える
以下のように設定すると、gemのインストール時にrustコードからコンパイルできるけど、本来の使い方ではない...
```ruby
Gem::Specification.new do |spec|
    spec.extensions = ['extconf.rb']
end
```
```ruby
# extconf.rb
require 'mkmf'
require_relative 'lib/calc_with_rust/rust_lib_conf'

# cargoの存在チェック
abort 'Error: cargoが見つかりません。cargoがインストールされているか確認してください。' unless find_executable('cargo')

puts 'Rustコードをビルドしています...'
Dir.chdir(CalcWithRust::RustLibConf::RUST_DIR) do
  abort 'Rustコードのビルドに失敗しました。' unless system('cargo build --release')
end

abort "ビルド成果物が見つかりません: #{lib_file_path}" unless File.exist?(CalcWithRust::RustLibConf::RUST_LIB_FILE_PATH)
create_makefile('dummy_extension')
```

---

## 感想とまとめ
ぼんやりしていた他言語連携の手法について、具体的な手法を知ることができた。
目指していた内部実装のコンパイル言語化と高速化が達成できた。
しかし、プロダクトにする = 誰でも動かせるようにする 観点でとても苦しんだ
 => バイナリは環境に依存するという宿命
 => NumPyは環境別にビルドしたものがpip installのときに適切に選ばれてダウンロードされるのだそう（ホイールという形式らしい）

コードさえあれば環境による差異はランタイムが吸収してくれるのはインタプリタ言語の非常に大きな強みだと実感した
 => 開発者はコードについてだけ考えていればいいので、とっても楽

gemでは、kaminariがC拡張を使っているらしいのでどのようにバイナリ管理しているのか見てみたい

---

# まつもとさんへ質問
いろいろ触るうちに、ランタイムのおかげで環境の差異を気にしなくていい、すなわちコードさえ渡せば基本的には同じ動作が期待できる。という点がインタプリタ言語は非常に強いなと感じました。
この、プログラマが環境のことをあまり考えなくていい特性は A PROGRAMMER'S BEST FRIEND というRubyのコピーに非常に通ずるところがあるなと思ったのですが、Rubyの仕様としてインタプリタ言語を選んだ背景にはこのような事情もあったのでしょうか？




