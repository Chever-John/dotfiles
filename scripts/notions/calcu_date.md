# 计算日期

```shell
if(prop("120 Days"), dateSubtract(prop("开始日期"), 1, "years"),prop("90 Days")?prop("120-d"): (if(prop("30 Days"), prop("90-d"), (if(prop("15 Days"), prop("30-d"), (if(prop("7 Days"), prop("15-d"), (if(prop("4 Days"), prop("7-d"), (if(prop("2 Days"), prop("4-d"), (if(prop("1 Day"), prop("2-d"), prop("1-d"))))))))))))))
```

备份

```shell
if(prop("120 Days"), dateSubtract(prop("开始日期"), 1, "years"),prop("90 Days")?prop("120-d"): (if(prop("30 Days"), prop("90-d"), (if(prop("15 Days"), prop("30-d"), (if(prop("7 Days"), prop("15-d"), (if(prop("4 Days"), prop("7-d"), (if(prop("2 Days"), prop("4-d"), (if(prop("1 Day"), prop("2-d"), prop("1-d"))))))))))))))
```

nk
