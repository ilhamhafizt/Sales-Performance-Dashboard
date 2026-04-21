"""
============================================================
Sales Performance Dashboard — Data Cleaning Script
Author  : Ilham Hafizt
Tools   : Python 3, Pandas, NumPy
Input   : sales_data_raw.csv   (2.500 raw / dirty rows)
Output  : sales_data_clean.csv (cleaned & validated rows)
============================================================

Masalah yang ditemukan di dataset mentah:
1. Duplikat order_id
2. Format tanggal tidak konsisten (yyyy-mm-dd, dd/mm/yyyy, mm-dd-yyyy, yyyymmdd, kosong, "N/A")
3. Nilai kosong / "N/A" / "-" pada kolom customer_name, rating, discount
4. Nama produk, kategori, region, channel, segment tidak konsisten huruf besar/kecil
5. Quantity mengandung nilai negatif, nol, dan non-numerik ("abc")
6. Unit price mengandung prefix "Rp", pemisah koma, nilai negatif, dan kosong
7. Discount_percent di luar rentang valid (0–100)
8. Rating di luar rentang valid (1.0–5.0) atau non-numerik
"""

import pandas as pd
import numpy as np
import re
from datetime import datetime

# ─── 0. LOAD ────────────────────────────────────────────────────────────────
print("=" * 60)
print("  SALES DATA CLEANING — STARTED")
print("=" * 60)

df = pd.read_csv("sales_data_raw.csv", dtype=str)
print(f"\n[LOAD] Raw rows     : {len(df):,}")
print(f"[LOAD] Columns      : {list(df.columns)}\n")


# ─── 1. HAPUS DUPLIKAT ──────────────────────────────────────────────────────
before = len(df)
df.drop_duplicates(subset=["order_id"], keep="first", inplace=True)
print(f"[1] Duplikat dihapus  : {before - len(df)} baris  →  {len(df):,} tersisa")


# ─── 2. NORMALISASI TEKS (case & whitespace) ────────────────────────────────
text_cols = [
    "product_name", "category", "region", "sales_channel",
    "customer_segment", "payment_method", "salesperson"
]

for col in text_cols:
    df[col] = df[col].str.strip().str.title()

# Standardisasi kategori
category_map = {
    "Electronics": "Electronics",
    "Peripherals": "Peripherals",
    "Furniture": "Furniture",
    "Accessories": "Accessories",
}
df["category"] = df["category"].map(
    lambda x: next((v for k, v in category_map.items() if k.lower() in str(x).lower()), "Other")
)

# Standardisasi produk (singkirkan varian huruf besar/kecil)
product_canonical = {
    "laptop pro x1": "Laptop Pro X1",
    "laptop pro x2": "Laptop Pro X2",
    "wireless mouse": "Wireless Mouse",
    "mechanical keyboard": "Mechanical Keyboard",
    "4k monitor": "4K Monitor",
    "usb-c hub": "USB-C Hub",
    "usb c hub": "USB-C Hub",
    "noise cancelling headset": "Noise Cancelling Headset",
    "headset": "Noise Cancelling Headset",
    "webcam hd": "Webcam HD",
    "external ssd 1tb": "External SSD 1TB",
    "external ssd": "External SSD 1TB",
    "gaming chair": "Gaming Chair",
    "desk lamp led": "Desk Lamp LED",
    "desk lamp": "Desk Lamp LED",
}
df["product_name"] = df["product_name"].apply(
    lambda x: next((v for k, v in product_canonical.items() if k == str(x).lower()), x)
)

# Standardisasi channel
channel_map = {
    "Online": "Online", "E-Commerce": "Online",
    "Offline": "Offline", "Direct Sales": "Offline",
}
df["sales_channel"] = df["sales_channel"].map(
    lambda x: next((v for k, v in channel_map.items() if k.lower() == str(x).lower()), str(x))
)

print(f"[2] Normalisasi teks  : selesai")


# ─── 3. PARSING TANGGAL ─────────────────────────────────────────────────────
def parse_date(val):
    if pd.isna(val) or str(val).strip() in ("", "N/A", "n/a", "NA"):
        return pd.NaT
    val = str(val).strip()
    formats = [
        "%Y-%m-%d",       # 2024-03-15
        "%d/%m/%Y",       # 15/03/2024
        "%m-%d-%Y",       # 03-15-2024
        "%Y%m%d",         # 20240315
        "%d-%m-%Y",
    ]
    for fmt in formats:
        try:
            return pd.to_datetime(val, format=fmt)
        except (ValueError, TypeError):
            continue
    try:
        return pd.to_datetime(val, infer_datetime_format=True, dayfirst=True)
    except Exception:
        return pd.NaT

df["order_date"] = df["order_date"].apply(parse_date)
null_dates = df["order_date"].isna().sum()
df.dropna(subset=["order_date"], inplace=True)
print(f"[3] Tanggal tidak valid dihapus : {null_dates} baris  →  {len(df):,} tersisa")

# Tambah kolom turunan
df["order_year"]  = df["order_date"].dt.year.astype(int)
df["order_month"] = df["order_date"].dt.month.astype(int)
df["order_month_name"] = df["order_date"].dt.strftime("%B")
df["order_quarter"] = df["order_date"].dt.quarter.astype(int).apply(lambda q: f"Q{q}")


# ─── 4. BERSIHKAN UNIT PRICE ────────────────────────────────────────────────
def clean_price(val):
    if pd.isna(val) or str(val).strip() in ("", "N/A"):
        return np.nan
    val = str(val)
    val = re.sub(r"[Rp\s,]", "", val)   # hapus "Rp", spasi, koma
    val = val.replace(",00", "")
    try:
        v = float(val)
        return v if v > 0 else np.nan
    except ValueError:
        return np.nan

df["unit_price"] = df["unit_price"].apply(clean_price)
before = len(df)
df.dropna(subset=["unit_price"], inplace=True)
print(f"[4] Harga tidak valid dihapus   : {before - len(df)} baris  →  {len(df):,} tersisa")


# ─── 5. BERSIHKAN QUANTITY ──────────────────────────────────────────────────
def clean_qty(val):
    try:
        v = int(float(str(val)))
        return v if v > 0 else np.nan
    except (ValueError, TypeError):
        return np.nan

df["quantity"] = df["quantity"].apply(clean_qty)
before = len(df)
df.dropna(subset=["quantity"], inplace=True)
df["quantity"] = df["quantity"].astype(int)
print(f"[5] Qty tidak valid dihapus     : {before - len(df)} baris  →  {len(df):,} tersisa")


# ─── 6. BERSIHKAN DISCOUNT ──────────────────────────────────────────────────
def clean_discount(val):
    try:
        v = float(str(val))
        return v if 0 <= v <= 100 else 0.0
    except (ValueError, TypeError):
        return 0.0

df["discount_percent"] = df["discount_percent"].apply(clean_discount)
print(f"[6] Diskon dibersihkan: nilai di luar 0–100 di-set ke 0")


# ─── 7. BERSIHKAN RATING ────────────────────────────────────────────────────
def clean_rating(val):
    if str(val).strip() in ("", "N/A", "n/a"):
        return np.nan
    try:
        v = float(str(val))
        return v if 1.0 <= v <= 5.0 else np.nan
    except (ValueError, TypeError):
        return np.nan

df["rating"] = df["rating"].apply(clean_rating)
# Imputasi rating null dengan median per produk
df["rating"] = df.groupby("product_name")["rating"].transform(
    lambda x: x.fillna(x.median())
)
print(f"[7] Rating dibersihkan: outlier dihapus, null diimputasi dengan median per produk")


# ─── 8. BERSIHKAN CUSTOMER NAME ─────────────────────────────────────────────
df["customer_name"] = df["customer_name"].str.strip()
df["customer_name"].replace(["", "N/A", "n/a", "-", "nan", "NaN"], np.nan, inplace=True)
df["customer_name"].fillna("Unknown Customer", inplace=True)
print(f"[8] Customer name kosong → 'Unknown Customer'")


# ─── 9. HITUNG KOLOM TURUNAN ────────────────────────────────────────────────
df["discount_amount"] = df["unit_price"] * df["quantity"] * (df["discount_percent"] / 100)
df["gross_sales"]     = df["unit_price"] * df["quantity"]
df["net_sales"]       = df["gross_sales"] - df["discount_amount"]
df["gross_sales"]     = df["gross_sales"].round(0).astype(int)
df["net_sales"]       = df["net_sales"].round(0).astype(int)
df["discount_amount"] = df["discount_amount"].round(0).astype(int)
df["unit_price"]      = df["unit_price"].round(0).astype(int)
print(f"[9] Kolom turunan ditambahkan: gross_sales, discount_amount, net_sales")


# ─── 10. SUSUN ULANG & SIMPAN ───────────────────────────────────────────────
final_cols = [
    "order_id", "order_date", "order_year", "order_month", "order_month_name", "order_quarter",
    "customer_name", "customer_segment",
    "product_name", "category",
    "region", "sales_channel", "payment_method", "salesperson",
    "quantity", "unit_price", "discount_percent", "discount_amount",
    "gross_sales", "net_sales", "rating"
]
df = df[final_cols]
df.sort_values("order_date", inplace=True)
df.reset_index(drop=True, inplace=True)

df.to_csv("sales_data_clean.csv", index=False, encoding="utf-8")

print("\n" + "=" * 60)
print("  CLEANING SELESAI")
print("=" * 60)
print(f"  Total baris bersih   : {len(df):,}")
print(f"  Rentang tanggal      : {df['order_date'].min().date()} → {df['order_date'].max().date()}")
print(f"  Total Net Sales      : Rp {df['net_sales'].sum():,.0f}")
print(f"  Rata-rata Rating     : {df['rating'].mean():.2f}")
print(f"  Output file          : sales_data_clean.csv")
print("=" * 60)
