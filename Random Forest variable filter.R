setwd("C:/Users/Administrator/Desktop/Project in HKBU/�½��ļ���")
library(readxl)
library(car)
library(e1071)
library(caret)


data1<-read_excel("data3.xlsx")
data2<-read_excel("2020������˾����ʱ�׼.xlsx")
unique(data1$ѧ��Ҫ��)


data1$ѧ��Ҫ��[which(data1$ѧ��Ҫ��=="��ʿ")]<-"4"
data1$ѧ��Ҫ��[which(data1$ѧ��Ҫ��=="˶ʿ")]<-"3"
data1$ѧ��Ҫ��[which(data1$ѧ��Ҫ��=="����")]<-"2"
data1$ѧ��Ҫ��[which(data1$ѧ��Ҫ��=="��ר")]<-"1"
data1$ѧ��Ҫ��[which(data1$ѧ��Ҫ��=="�м�")]<-"0"
data1$ѧ��Ҫ��[which(data1$ѧ��Ҫ��=="��ר")]<-"0"
data1$ѧ��Ҫ��[which(data1$ѧ��Ҫ��=="����")]<-"0"


for (i in data1$���ڵ�) {
  data1$���ڵ�[which(data1$���ڵ�==i)]<-data2$ƽ������[which(data2$����==i)]
  
}

data1$ѧ��Ҫ��<-as.numeric(data1$ѧ��Ҫ��)
data1$���ڵ�<-as.numeric(data1$���ڵ�)

data3<-subset(data1,select=-c(ְλ����,ְλ���,ְλ����,��Ƹ����,��˾����,����,����,��˾����,
                                keywords_ְλ���,keywords_ְλ����,keywords_����,keywords_��˾����))
data3<- na.exclude(data3)

write.table (data3, file ="resultCsv.csv", sep =",", row.names =FALSE)

##############################################################
#���۽�����֤�������ɭ�ֱ���

a=data3[,1]

CVgroup <- function(k, datasize, seed) {
  cvlist <- list()
  set.seed(seed)
  n <- rep(1:k, ceiling(datasize/k))[1:datasize] #�����ݷֳ�K�ݣ������ɵ��������ݼ�n
  temp <- sample(n, datasize)  #��n����
  x <- 1:k
  dataseq <- 1:datasize 
  cvlist <- lapply(x, function(x) dataseq[temp==x])  #dataseq���������10���������������
  return(cvlist)
}

k <- 5
datasize <- nrow(data3)
cvlist <- CVgroup(k = k, datasize = datasize, seed = 1206)


data <- data3
pred <- data.frame() #�洢Ԥ����
library(plyr)
m <- seq(60, 100, by = 5)                        ##������������������㣬�����Сû��ʵ������
for (j in m) {                                    #jָ�������ɭ����������
  progress.bar <- create_progress_bar("text")     #��`create_progress_bar`��������һ����������plyr����
  progress.bar$init(k)                            #��������������������۾��Ǽ�������
  
  for (i in 1:k) {
    train <- data[-cvlist[[i]],]                     #�ղ�ͨ��cvgroup���ɵĺ���
    test <- data[cvlist[[i]],]
    
    model <- randomForest(н�� ~ ., data = train, ntree = j)   #��ģ��ntree=Jָ������
    prediction <- predict(model, subset(test, select = - н��))#Ԥ��
    
    randomtree <- rep(j, length(prediction))          #���ɭ����������
    
    kcross <- rep(i, length(prediction))              #i�ڼ���ѭ�����棬��K��
    
    temp <- data.frame(cbind(subset(test, select = н��), prediction, randomtree, kcross))
    #��ʵֵ��Ԥ��ֵ�����ɭ����������������������һ������µ����ݿ�temp
    pred <- rbind(pred, temp) #temp���к�pred�ϲ�
    print(paste("���ɭ�֣�", j))
    #ѭ��������j�����ɭ��ģ�͡��������ǾͿ��Ը���pred��¼�Ľ�����з�������ȵȣ���һ���о����������ɭ��׼ȷ�Լ��ȶ��е�Ӱ�졣
    progress.bar$step()
    #19���������������֪������������İٷ�֮��
  }
}
##############################################################

library(dplyr)
maefun <- function(pred, obs) mean(abs(pred - obs))
msefun <- function(pred, obs) mean((pred - obs)^2)
nmsefun <- function(pred, obs) mean((pred - obs)^2)/mean((mean(obs) - obs)^2)
eval <- pred %>% group_by(randomtree, kcross) %>%   #randomtree=j��kcross=i
  summarise(mae = maefun(prediction, н��),
            mse = msefun(prediction, н��),
            nmse = nmsefun(prediction, н��))

eval1<-eval
##############################################################
#�鿴65�����ɭ�ֱ��֣�ɸѡ����
library(randomForest)
library(varSelRF)
library(pROC)

#��index���ѵ��������Լ�
index <- sample(2,nrow(data3),replace = TRUE,prob=c(0.8,0.2))
traindata <- data3[index==1,]
testdata <- data3[index==2,]

#������ѵ��ģ��
set.seed(1234)#���������������ȷ���Ժ���ִ�д���ʱ���Եõ�һ���Ľ��

salary_rf <- randomForest(н�� ~ ., data=traindata,
                            ntree=65,important=TRUE)
salary_rf

salary_pred<-predict(salary_rf, newdata=testdata)
table(salary_pred,testdata$н��)
roc<-multiclass.roc (as.ordered(testdata$н��) ,as.ordered(salary_pred))
roc

varImpPlot(salary_rf)
im=importance(salary_rf)
im[order(im[,1],decreasing=T),]
##############################################################
#����ɸѡ���ٴν������۽�����֤
data4<-subset(data3,select=c(н��,����Ҫ��,ѧ��Ҫ��,���ڵ�,��ģ,����_19,��˾����_46,����_34,ְλ����_41,
                                 ְλ����_24,����_22,ְλ���_45,ְλ���_15,ְλ����_33,����_35,ְλ����_25))

a=data4[,1]

CVgroup <- function(k, datasize, seed) {
  cvlist <- list()
  set.seed(seed)
  n <- rep(1:k, ceiling(datasize/k))[1:datasize] #�����ݷֳ�K�ݣ������ɵ��������ݼ�n
  temp <- sample(n, datasize)  #��n����
  x <- 1:k
  dataseq <- 1:datasize 
  cvlist <- lapply(x, function(x) dataseq[temp==x])  #dataseq���������10���������������
  return(cvlist)
}

k <- 5
datasize <- nrow(data4)
cvlist <- CVgroup(k = k, datasize = datasize, seed = 1206)


data <- data4
pred <- data.frame() #�洢Ԥ����
library(plyr)
m <- seq(5, 100, by = 5)                        ##������������������㣬�����Сû��ʵ������
for (j in m) {                                    #jָ�������ɭ����������
  progress.bar <- create_progress_bar("text")     #��`create_progress_bar`��������һ����������plyr����
  progress.bar$init(k)                            #��������������������۾��Ǽ�������
  
  for (i in 1:k) {
    train <- data[-cvlist[[i]],]                     #�ղ�ͨ��cvgroup���ɵĺ���
    test <- data[cvlist[[i]],]
    
    model <- randomForest(н�� ~ ., data = train, ntree = j)   #��ģ��ntree=Jָ������
    prediction <- predict(model, subset(test, select = - н��))#Ԥ��
    
    randomtree <- rep(j, length(prediction))          #���ɭ����������
    
    kcross <- rep(i, length(prediction))              #i�ڼ���ѭ�����棬��K��
    
    temp <- data.frame(cbind(subset(test, select = н��), prediction, randomtree, kcross))
    #��ʵֵ��Ԥ��ֵ�����ɭ����������������������һ������µ����ݿ�temp
    pred <- rbind(pred, temp) #temp���к�pred�ϲ�
    print(paste("���ɭ�֣�", j))
    #ѭ��������j�����ɭ��ģ�͡��������ǾͿ��Ը���pred��¼�Ľ�����з�������ȵȣ���һ���о����������ɭ��׼ȷ�Լ��ȶ��е�Ӱ�졣
    progress.bar$step()
    #19���������������֪������������İٷ�֮��
  }
}
maefun <- function(pred, obs) mean(abs(pred - obs))
msefun <- function(pred, obs) mean((pred - obs)^2)
nmsefun <- function(pred, obs) mean((pred - obs)^2)/mean((mean(obs) - obs)^2)
eval <- pred %>% group_by(randomtree, kcross) %>%   #randomtree=j��kcross=i
  summarise(mae = maefun(prediction, н��),
            mse = msefun(prediction, н��),
            nmse = nmsefun(prediction, н��))

eval2<-eval
##############################################################
#25�����ɭ��ģ��
index <- sample(2,nrow(data4),replace = TRUE,prob=c(0.8,0.2))
traindata <- data4[index==1,]
testdata <- data4[index==2,]

#������ѵ��ģ��
set.seed(1234)#���������������ȷ���Ժ���ִ�д���ʱ���Եõ�һ���Ľ��

salary_rf <- randomForest(н�� ~ ., data=traindata,
                            ntree=40,important=TRUE)
salary_rf

salary_pred<-predict(salary_rf, newdata=testdata)
table(salary_pred,testdata$н��)
roc<-multiclass.roc (as.ordered(testdata$н��) ,as.ordered(salary_pred))
roc

varImpPlot(salary_rf)

plot(salary_rf)


