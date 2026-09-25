# DATASET
- All data files live in `data/`, which is git-ignored.
- NASDAQ's md5sum server returns a 404 error, so checksums below are self-certified by computing locally after download
  
## Development – PSX TotalView-ITCH 5.0 (2019-12-30)
|Item            | Value                                                                  |
|----------------|------------------------------------------------------------------------|
| Source         | https://emi.nasdaq.com/ITCH/Nasdaq%20PSX%20ITCH/20191230.PSX_ITCH_50.gz|
| Compressed     | `20191230.PSX_ITCH_50.gz` (507MB)                                      |
| Raw            | `20191230.PSX_ITCH_50` (1.2 GB)                                        |
| MD5sum (gz)    | `0010c0ef456bdd0bfdb14cccf5a45ba2`                                     |

## Headline – NASDAQ TotalView-ITCH 5.0 (2019-12-30)
| Item             | Value                                                                 |
|------------------|-----------------------------------------------------------------------|
| Source           | https://emi.nasdaq.com/ITCH/Nasdaq%20ITCH/12302019.NASDAQ_ITCH50.gz/  |
| Compressed       | `12302019.NASDAQ_ITCH50.gz` (3.3GB)                                   |
| Raw              | `12302019.NASDAQITCH_50` (7.7 GB)                                     |
| MD5Sum (gz)      | `23514ef98821448a3f8f4c5b4095f3f5`                                    |

## Fixture
A small fixture (`tests/fixture/`) is for unit tests and CI. It contains ITCH messages covering every message type used. 
