# Japanese prefectures, used for delivery areas and project locations. Plain Ruby, no table.
class Prefecture
  ALL = %w[
    Hokkaido Aomori Iwate Miyagi Akita Yamagata Fukushima
    Ibaraki Tochigi Gunma Saitama Chiba Tokyo Kanagawa
    Niigata Toyama Ishikawa Fukui Yamanashi Nagano Gifu Shizuoka Aichi
    Mie Shiga Kyoto Osaka Hyogo Nara Wakayama
    Tottori Shimane Okayama Hiroshima Yamaguchi
    Tokushima Kagawa Ehime Kochi
    Fukuoka Saga Nagasaki Kumamoto Oita Miyazaki Kagoshima Okinawa
  ].freeze

  KANTO = %w[Tokyo Kanagawa Saitama Chiba Ibaraki Tochigi Gunma].freeze
end
