# Order-Brushing-Detection 

This repo contains data and R code for Order Brushing Detection Task in E-Commerce Industry, part of Shopee Code League Competition hosted on Kaggle.

If you not familiar with the term, it refers to seller misconduct activity done by creating fake transaction (i.e buyer-bot). This act, according to Shopee's Terms of Service, is in fact illegal. 

The main indicator is transaction volume. 

if the transaction volume done by seller-buyer reached certain threshold (for our purposes, let's say it's 3) with one hour interval, then we can suspect the seller might have done order brushing. if this is the case, then we put seller id and list of buyer-bot (with format buyer1&buyer2&buyer3&...&buyerN) side by side. else, we put seller and "0" side by side.

This task is important because we want to protect the endorsement system integrity within said E-Commerce company. 


