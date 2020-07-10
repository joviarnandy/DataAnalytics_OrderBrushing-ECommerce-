#load library
library(data.table)
library(plyr)
library(dplyr)

#read data
data = fread("order_brush_order.csv",stringsAsFactors = T,data.table = F)


#remove orderid
data$orderid = NULL


#'summarize' data
x = data %>% 
  group_by(shopid,userid) %>%
  summarise(count=n()) %>%
  as.data.frame()


#extract order brushing candidate
y = subset(x, rowSums(x[3] >= 3) > 0) #count column is the third column of x
candidate = left_join(y,data)
candidate$event_time = as.POSIXct(candidate$event_time)
candidate$shopid = as.factor(candidate$shopid)
candidate$userid = as.factor(candidate$userid)
candidate$count = NULL
candidate = candidate %>%
  group_by(shopid,userid) %>%
  arrange(shopid,userid,event_time) %>%
  as.data.frame()

#perform trivial order brushing detection 
user = data.frame(
  userid=character(length(unique(x$shopid))), 
  stringsAsFactors=FALSE) 
submission = cbind.data.frame(as.data.frame(unique(x$shopid)),user)
colnames(submission) = c("shopid","userid")
t1 = as.data.frame(submission$shopid)
colnames(t1) = "shopid"
t2 = as.data.frame(unique(y$shopid))
colnames(t2) = "shopid"
picklerick = setdiff(t1,t2)
picklerick$userid = "0"
usernew = data.frame(
  userid=character(length(unique(y$shopid))), 
  stringsAsFactors=FALSE)
picklemorty = cbind.data.frame(t2,usernew)
submission = rbind.data.frame(picklerick,picklemorty)

## OPTIONAL ##
submission = submission %>% 
  arrange(shopid)
submission$shopid = as.character(submission$shopid)
rownames(y) = NULL
y$is_suspected = NA
z = y[,1:2]
candidate$counter = 1
rm(list=setdiff(ls(), c("data","candidate","submission","y","z")))


# perform non-trivial order brushing detection
#reference:
#"https://stackoverflow.com/a/38019854" )
#https://rdrr.io/cran/plyr/man/match_df.html
for (i in 1:(dim(z)[1])){
  my_exp = match_df(candidate,z[i,])
  ok = my_exp %>%
    mutate(event_timestamp = as.POSIXct(event_time, format = '%m/%d/%Y %H:%M'),
           row_count = as.numeric(counter)) %>%
    mutate(window = cut(event_timestamp, '60 min')) %>%
    group_by(window) %>%
    dplyr::summarise(row_counts = sum(row_count))
  y$is_suspected[i] = any(ok$row_counts>=3)
}
rm(list=setdiff(ls(), c("data","candidate","submission","y")))
crop_y = y[which(y$is_suspected==TRUE),]
rownames(crop_y) = NULL
suspect_shop = as.data.frame(unique(crop_y$shopid))
colnames(suspect_shop) = "shopid"
for (i in 1: (dim(suspect_shop)[1])){
  crop_y$suspect_user[i] = paste0(crop_y[crop_y$shopid == suspect_shop$shopid[i],]$userid
                                  ,collapse = "&") 
}
rm(list=setdiff(ls(), c("data","candidate","submission","y","crop_y")))
y = left_join(y,crop_y)
y[is.na(y)] = "0"
submission = submission[!(submission$userid==""), ]
rm(list=setdiff(ls(), c("data","candidate","submission","y")))
star_platinum = cbind.data.frame(as.data.frame(y$shopid),as.data.frame(y$suspect_user)
)
colnames(star_platinum) = c("shopid","userid")
star_platinum = as.data.frame(unique(star_platinum))
rm(list=setdiff(ls(), c("submission","star_platinum")))
polnareff = as.data.frame(unique(star_platinum$shopid))
colnames(polnareff) = "shopid"
for (j in 1:(dim(polnareff)[1])){
  t = star_platinum[(star_platinum$shopid==polnareff$shopid[j]), ]
  if (dim(t)[1] > 1){
    polnareff$userid[j] =  paste0(t[which(t$userid!="0"),]$userid,collapse="&")  
  }
  else if (dim(t)[1] == 1){
    polnareff$userid[j] = t$userid
  }
}
rm(list=setdiff(ls(), c("submission","polnareff")))
polnareff$shopid = as.character(polnareff$shopid)
submission = rbind.data.frame(submission,polnareff)
submission = submission %>%
  arrange(shopid)



#write submission's csv file
write.csv(submission,"submission.csv")
cat("\014")


