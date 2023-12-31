## ----knitr,echo=FALSE---------------------------------------------------------
knitr::opts_chunk$set(eval=FALSE,echo=TRUE)

## ----init,echo=TRUE-----------------------------------------------------------
#  rm(list=ls())
#  dir <- "~/Desktop/transreg" # physical machine
#  #dir <- "/home/armin.rauschenberger/transreg" # virtual machine
#  setwd(dir)
#  if(!all(c("data","results","manuscript") %in% dir())){
#   stop("Missing folders!")
#  }

## ----pkgs,eval=FALSE,echo=TRUE------------------------------------------------
#  pkgs <- c("devtools","palasso","glmtrans","xtable","ecpc","xrnet")
#  utils::install.packages(setdiff(pkgs,rownames(installed.packages())))
#  remotes::install_github("markvdwiel/GRridge") # ref="ef706afe", version 1.7.5
#  remotes::install_github("kjytay/fwelnet") # ref="5515fd2e", version 0.1
#  remotes::install_github("LCSB-BDS/transreg") # ref="82757441", version 1.0.0
#  rm(pkgs)

## ----calibration,echo=TRUE----------------------------------------------------
#  #<<init>>
#  #grDevices::pdf(file=paste0(dir,"/manuscript/figure_example.pdf"),width=8,height=5,pointsize=15)
#  #grDevices::png(file=paste0(dir,"/manuscript/figure_example.png"),width=8,height=5,units="in",pointsize=15,res=1200)
#  grDevices::postscript(file=paste0(dir,"/manuscript/figure_example.eps"),width=8,height=5,pointsize=15,horizontal=FALSE,paper="special")
#  
#  set.seed(1)
#  n <- 200; p <- 500
#  X <- matrix(stats::rnorm(n*p),nrow=n,ncol=p)
#  temp <- stats::rnorm(p)
#  range <- stats::qnorm(p=c(0.01,0.99))
#  temp[temp<range[1]] <- range[1]
#  temp[temp>range[2]] <- range[2]
#  
#  beta <- list()
#  beta$ident <- temp
#  beta$sqrt <- sign(temp)*sqrt(abs(temp))
#  beta$quad <- sign(temp)*abs(temp)^2
#  beta$trunc <- ifelse(temp<=0,0,temp)
#  beta$step <- ifelse(temp<=1,0,1)
#  beta$combn <- ifelse(temp<0,sign(temp)*sqrt(abs(temp)),sign(temp)*abs(temp)^2)
#  
#  graphics::par(mfrow=c(2,3),mar=c(3,3,0.5,0.5))
#  for(i in seq_along(beta)){
#  
#    prior <- matrix(temp,ncol=1)
#    eta <- X %*% beta[[i]]
#    y <- stats::rnorm(n=n,mean=eta,sd=sd(eta))
#    a <- transreg:::.exp.multiple(y=y,X=X,prior=prior,family="gaussian",select=FALSE)
#    b <- transreg:::.iso.fast.single(y=y,X=X,prior=prior,family="gaussian")
#  
#    graphics::plot.new()
#    graphics::plot.window(xlim=range(prior,-prior),ylim=range(a$beta,b$beta))
#    graphics::axis(side=1)
#    graphics::axis(side=2)
#    graphics::abline(h=0,lty=2,col="grey")
#    graphics::abline(v=0,lty=2,col="grey")
#    graphics::box()
#    graphics::title(xlab=expression(z),ylab=expression(gamma),line=2)
#    graphics::points(x=prior,y=a$beta,col="red",cex=0.7)
#    graphics::points(x=prior,y=b$beta,col="blue",cex=0.7)
#    graphics::lines(x=prior[order(prior)],y=beta[[i]][order(prior)],lwd=1.2)
#    graphics::legend(x="topleft",legend=paste0("(",i,")"),bty="n",x.intersp=0)
#  }
#  
#  grDevices::dev.off()

## ----sim_script,eval=FALSE,echo=TRUE------------------------------------------
#  #<<init>>
#  
#  # - - - modify glmtrans::models function - - -
#  glmtrans.models <- glmtrans::models
#  string <- base::deparse(glmtrans.models)
#  # return target beta
#  string <- gsub(pattern="list\\(x \\= NULL, y \\= NULL\\)",
#                 replacement="list(x = NULL, y = NULL, beta = wk)",
#                 x=string)
#  # return source beta
#  string <- gsub(pattern="list\\(x \\= x, y \\= y\\)",
#                 replacement="list(x = x, y = y, beta = wk)",
#                 x=string)
#  glmtrans.models <- eval(parse(text=string))
#  rm(string)
#  # - - - - - - - - - - - - - - - - - - - - - -
#  
#  for(mode in c("ext","int")){
#  
#      # simulation setting
#      if(mode=="ext"){
#        frame <- expand.grid(seed=1:10,
#                             Ka=as.integer(c(1,3,5)),
#                             K=as.integer(5),
#                             h=as.integer(c(5,250)),
#                             alpha=as.integer(c(0,1)),
#                             family=c("gaussian","binomial")
#                             )
#      } else if(mode=="int"){
#        frame <- expand.grid(seed=1:10,
#                             rho.x=c(0.95,0.99),
#                             rho.beta=c(0.6,0.8,0.99),
#                             alpha=as.integer(c(0,1)),
#                             family=c("gaussian","binomial")
#                             )
#      }
#      frame$family <- as.character(frame$family)
#      frame[,c("cor.x","cor.beta","mean","glmnet","glmtrans","transreg")] <- NA
#      n0 <- 100; n1 <- 10000
#      n.target <- n0+n1
#      foldid.ext <- rep(c(0,1),times=c(n0,n1))
#  
#      for(iter in seq_len(nrow(frame))){
#        cat(paste0(mode,": ",iter,"/",nrow(frame),"\n"))
#  
#        if(!is.na(frame$seed[iter])){set.seed(frame$seed[iter])}
#  
#        # data simulation
#        if(mode=="ext"){
#          message("Using external simulation study!")
#          s <- ifelse(frame$alpha[iter]==0,50,15)
#          data <- glmtrans.models(family=frame$family[iter],type="all",
#                                  p=1000,n.target=n.target,s=s,
#                                  Ka=frame$Ka[iter],K=frame$K[iter],h=frame$h[iter])
#          target <- data$target
#          source <- data$source
#          beta <- cbind(sapply(data$source,function(x) x$beta),data$target$beta)
#        } else if(mode=="int"){
#          message("Using internal simulation study!")
#          prop <- ifelse(frame$alpha[iter]==0,0.3,0.05)
#          data <- transreg:::simulate(p=500,n.target=n.target,family=frame$family[iter],
#                                  prop=prop,rho.beta=frame$rho.beta[iter],w=0.8,
#                                  rho.x=frame$rho.x[iter],k=3,exp=c(1,2,0.5),
#                                  trans=c(FALSE,TRUE,TRUE))
#          target <- data$target
#          source <- data$source
#          beta <- data$beta
#        }
#  
#        # correlation
#        temp <- abs(stats::cor(data$target$x,method="pearson"))
#        temp[lower.tri(temp,diag=TRUE)] <- NA
#        frame$cor.x[iter] <- mean(temp,na.rm=TRUE)
#        temp <- abs(stats::cor(beta,method="pearson"))
#        temp[lower.tri(temp,diag=TRUE)] <- NA
#        frame$cor.beta[iter] <- max(temp[,ncol(temp)],na.rm=TRUE)
#  
#        # predictive performance
#        loss <- transreg:::compare(target=target,source=source,
#                            family=frame$family[iter],alpha=frame$alpha[iter],
#                            foldid.ext=foldid.ext,nfolds.ext=1,
#                            scale=c("exp","iso"),
#                            sign=FALSE,switch=FALSE,select=TRUE,alpha.prior=NULL,
#                            seed=frame$seed[iter],xrnet=TRUE)
#        frame[iter,names(loss$deviance)] <- loss$deviance
#      }
#      save(frame,file=paste0(dir,"/results/sim_",mode,".RData"))
#  }
#  writeLines(text=capture.output(utils::sessionInfo(),cat("\n"),
#        sessioninfo::session_info()),con=paste0(dir,"/results/info_sim.txt"))

## ----sim_table,echo=TRUE------------------------------------------------------
#  rm(list=ls())
#  dir <- "~/Desktop/transreg" # physical machine
#  #dir <- "/home/armin.rauschenberger/transreg" # virtual machine
#  setwd(dir)
#  if(!all(c("data","results","manuscript") %in% dir())){
#   stop("Missing folders!")
#  }
#  for(mode in c("ext","int")){
#      file <- paste0(dir,"/results/sim_",mode,".RData")
#      #if(mode=="int"){file <- "~/Desktop/transreg/results/sim_int_fast.RData"}
#      if(!file.exists(file)){warning("Missing file ",file,".");next}
#      load(file)
#      colnames(frame) <- gsub(pattern="transreg.",replacement="",x=colnames(frame))
#  
#      info.var <- c("Ka","h","rho.x","rho.beta","alpha","family")
#      info <- frame[,colnames(frame) %in% info.var]
#      info.name <- gsub(pattern=" ",replacement="",x=apply(info,1,function(x) paste0(x,collapse=".")))
#      number <- as.numeric(factor(info.name,levels=unique(info.name)))
#      info <- unique(info)
#      info$cor.beta <- info$cor.x <- NA
#  
#      loss.var <- c("glmnet","glmtrans","xrnet","exp.sta","exp.sim","iso.sta","iso.sim")
#      loss <- frame[,c(loss.var,"mean")]
#      # as percentage of empty model
#      loss <- 100*loss/loss$mean
#  
#      # average over 10 different seeds
#      both <- mean <- sd <- p.better <- p.worse <- matrix(NA,nrow=max(number),ncol=length(loss.var),dimnames=list(1:max(number),loss.var))
#      for(i in 1:max(number)){
#        for(j in seq_along(loss.var)){
#          cond <- number==i
#          x <- loss$glmnet[cond]
#          y <- loss[[loss.var[j]]][cond]
#          p.better[i,j] <- stats::wilcox.test(x=x,y=y,paired=TRUE,alternative="greater",exact=FALSE)$p.value
#          p.worse[i,j] <- stats::wilcox.test(x=x,y=y,paired=TRUE,alternative="less",exact=FALSE)$p.value
#          mean[i,j] <- mean(y)
#          sd[i,j] <- sd(y)
#          info$cor.x[i] <- mean(frame$cor.x[cond])
#          info$cor.beta[i] <- mean(frame$cor.beta[cond])
#        }
#      }
#  
#      front <- format(round(mean,digits=1),trim=TRUE)
#      front.nchar <- nchar(front)
#      back <- format(round(sd,digits=1),trim=TRUE)
#      back.nchar <- nchar(back)
#  
#      both[] <- paste0(front,"$\\pm$",back)
#  
#      grey <- mean>=mean[,"glmnet"]
#      both[grey] <- paste0("\\textcolor{gray}{",both[grey],"}")
#  
#      min <- cbind(seq_len(max(number)),apply(mean,1,which.min))
#      both[min] <- paste0("\\underline{",both[min],"}")
#  
#      star <- p.better<=0.05
#      both[star] <- paste0(both[star],"*")
#      #both[!star] <- paste0(both[!star],"\\phantom{*}")
#  
#      dagger <- p.worse<=0.05
#      both[dagger] <- paste0(both[dagger],"$\\dagger$")
#      both[!star & !dagger] <- paste0(both[!star & !dagger],"\\phantom{*}")
#  
#      both[front.nchar==3] <- paste0("$~$",both[front.nchar==3])
#      both[back.nchar==3] <- paste0(both[back.nchar==3],"$~$")
#  
#      external <- "number of transferable source data sets ($K_a$), differences between source and target coefficients ($h$), dense setting with ridge regularisation ($s=50$, $\\alpha=0$) or sparse setting with lasso regularisation ($s=15$, $\\alpha=1$), family of distribution (`gaussian' or `binomial')."
#      internal <- "correlation parameter for features ($\\rho_x$), correlation parameter for coefficients ($\\rho_{\\beta}$), dense setting with ridge regularisation ($\\pi=30\\%$, $\\alpha=0$) or sparse setting with lasso regularisation ($\\pi=5\\%$, $\\alpha=1$), family of distribution (`gaussian' or `binomial')."
#      caption <- paste0("Predictive performance in ",mode,"ernal simulation. In each setting (row), we simulate $10$ data sets, calculate the performance metric (mean-squared error for numerical prediction, logistic deviance for binary classification) for the test sets, express these metrics as percentages of those from prediction by the mean, and show the mean and standard deviation of these percentages. Settings: ",ifelse(mode=="ext",external,ifelse(mode=="int",internal,NULL))," These parameters determine (i) the mean Pearson correlation among the features in the target data set ($\\bar{\\rho}_x$) and (ii) the maximum Pearson correlation between the coefficients in the target data set and the coefficients in the source data sets ($\\max(\\hat{\\rho}_{\\beta})$). Methods: regularised regression (\\texttt{glmnet}), competing transfer learning methods (\\texttt{glmtrans} , \\texttt{xrnet}), proposed transfer learning method (\\texttt{transreg}) with exponential/isotonic calibration and standard/simultaneous stacking. In each setting, the colour black (grey) highlights methods that are more (less) predictive than regularised regression without transfer learning (\\texttt{glmnet}), asterisks (daggers) indicate methods that are \\textit{significantly} more (less) predictive at the 5\\% level (one-sided Wilcoxon signed-rank test), and an underline highlights the most predictive method. \\label{sim_",mode,"}")
#  
#      colnames(info) <- sapply(colnames(info),function(x) switch(x,"Ka"="$K_a$","K"="$K$","h"="$h$","alpha"="$\\alpha$","rho.x"="$\\rho_x$","rho.beta"="$\\rho_\\beta$","cor.x"="$\\bar{\\rho}_{x}$","cor.beta"="$\\max(\\hat{\\rho}_{\\beta})$","cor.t"="$\\bar{\\rho}_{a}$",x))
#      colnames(both) <- paste0("\\texttt{",colnames(both),"}")
#  
#      align <- paste0("|r|",paste0(rep("c",times=ncol(info)),collapse=""),"|",paste0(rep("c",times=ncol(both)),collapse=""),"|")
#  
#      add.to.row <- list()
#      add.to.row$pos <- list(-1)
#      add.to.row$command <- "\\multicolumn{9}{c}{~} & \\multicolumn{4}{|c|}{\\texttt{transreg}}\\\\"
#  
#      xtable <- xtable::xtable(x=cbind(info,both),align=align,caption=caption)
#      xtable::print.xtable(x=xtable,
#                  include.rownames=FALSE,
#                  floating=TRUE,
#                  sanitize.text.function=identity,
#                  comment=FALSE,
#                  caption.placement="top",
#                  floating.environment="table*",
#                  #size="\\small \\setlength{\\tabcolsep}{3pt}",
#                  file=paste0(dir,"/manuscript/table_",mode,".tex"),
#                  add.to.row=add.to.row,
#                  hline.after=c(-1,0,nrow(xtable)))
#  }

## ----grridge_script,eval=FALSE,echo=TRUE--------------------------------------
#  #<<init>>
#  data(dataVerlaat,package="GRridge")
#  
#  target <- list()
#  target$y <- as.numeric(as.factor(respVerlaat))-1
#  target$x <- t(datcenVerlaat)
#  
#  z <- -log10(pvalFarkas) # ecpc and fwelnet
#  prior <- sign(diffmeanFarkas)*(-log10(pvalFarkas)) # transreg
#  
#  loss <- list()
#  for(i in 1:10){
#    cat("---",i,"---\n")
#    loss[[i]] <- transreg:::compare(target=target,prior=prior,z=as.matrix(z,ncol=1),
#                                      family="binomial",alpha=0,scale=c("exp","iso"),sign=FALSE,switch=FALSE,select=FALSE,type.measure=c("deviance","class","auc"),seed=i,xrnet=TRUE)
#  }
#  save(loss,file=paste0(dir,"/results/app_grridge.RData"))
#  writeLines(text=capture.output(utils::sessionInfo(),cat("\n"),
#        sessioninfo::session_info()),con=paste0(dir,"/results/info_app_grridge.txt"))
#  
#  load(paste0(dir,"/results/app_grridge.RData"),verbose=TRUE)
#  table <- as.data.frame(t(sapply(loss,function(x) x$deviance)))
#  table <- (table-table$glmnet)/table$glmnet
#  table <- table[,c("glmnet","transreg.exp.sta","transreg.exp.sim","transreg.iso.sta","transreg.iso.sim","fwelnet","ecpc","xrnet")]
#  sapply(table[,-1],function(x) sum(x<table$glmnet))
#  round(100*colMeans(table[,-1]),digits=2)

## ----fwelnet_script,eval=FALSE,echo=TRUE--------------------------------------
#  #<<init>>
#  
#  table <- utils::read.csv("data/pone.0181468.s001.csv",header=TRUE,skip=3)
#  
#  extract <- function(cond,y,X,id){
#    if(length(unique(c(length(cond),length(y),nrow(X),length(id))))!=1){stop("Invalid input.")}
#    n <- table(id,cond)[,"TRUE"]
#    y <- y[cond]
#    X <- X[cond,]
#    id <- id[cond]
#    weights <- rep(1/n,times=n)
#    ids <- unique(id)
#    ys <- sapply(ids,function(x) unique(y[id==x]))
#    foldid <- rep(NA,length=length(ids))
#    foldid[ys==0] <- sample(rep(1:10,length.out=sum(ys==0)))
#    foldid[ys==1] <- sample(rep(1:10,length.out=sum(ys==1)))
#    foldid <- rep(foldid,times=n[n!=0])
#    if(length(unique(c(length(y),nrow(X),length(weights),length(foldid))))!=1){
#      stop("Invalid output.")
#    }
#    return(list(y=y,x=X,weights=weights,foldid=foldid))
#  }
#  
#  loss <- ridge <- lasso <- list()
#  for(i in 1:10){
#    cat("---",i,"---\n")
#    set.seed(i)
#  
#    y <- table$LatePE
#    X <- as.matrix(table[,grepl(pattern="SL",x=colnames(table))])
#    X <- scale(X)
#  
#    min <- sapply(unique(table$ID),function(i) min(table$GA[table$ID==i]))
#    max <- sapply(unique(table$ID),function(i) max(table$GA[table$ID==i]))
#  
#    limit <- 20
#    group <- stats::rbinom(n=max(table$ID),size=1,prob=0.5)
#    source.id <- which(group==0 | min > limit)
#    target.id <- which(group==1 & min <= limit)
#    if(any(!table$ID %in% c(source.id,target.id))){stop()}
#    if(any(!c(source.id,target.id) %in% table$ID)){stop()}
#    if(any(duplicated(c(source.id,target.id)))){stop()}
#  
#    source <- list()
#    source[[1]] <- extract(cond=(table$ID %in% source.id) & (table$GA<=limit),y=y,X=X,id=table$ID)
#    source[[2]] <- extract(cond=(table$ID %in% source.id),y=y,X=X,id=table$ID)
#  
#    prior <- z <- matrix(NA,nrow=ncol(X),ncol=length(source))
#    for(j in seq_along(source)){
#      base <- glmnet::cv.glmnet(y=source[[j]]$y,x=source[[j]]$x,
#                                family="binomial",alpha=0,
#                                weights=source[[j]]$weights,
#                                foldid=source[[j]]$foldid)
#      prior[,j] <- coef(base,s="lambda.min")[-1]
#      z[,j] <- abs(coef(base,s="lambda.min")[-1])
#    }
#  
#    target <- list()
#    target$y <- sapply(target.id,function(i) unique(y[table$ID==i]))
#    target$x <- t(sapply(target.id,function(i) X[table$ID==i & table$GA==min(table$GA[table$ID==i]),]))
#  
#    loss[[i]] <- transreg:::compare(target=target,prior=prior,family="binomial",alpha=0,scale=c("exp","iso"),sign=FALSE,switch=FALSE,select=FALSE,z=z,type.measure=c("deviance","class","auc"),seed=i,xrnet=TRUE)
#  }
#  save(loss,file=paste0(dir,"/results/app_fwelnet.RData"))
#  writeLines(text=capture.output(utils::sessionInfo(),cat("\n"),
#        sessioninfo::session_info()),con=paste0(dir,"/results/info_app_fwelnet.txt"))
#  
#  load(paste0(dir,"/results/app_fwelnet.RData"))
#  table <- as.data.frame(t(sapply(loss,function(x) x$deviance)))
#  table <- (table-table$glmnet)/table$glmnet
#  table <- table[,c("glmnet","transreg.exp.sta","transreg.exp.sim","transreg.iso.sta","transreg.iso.sim","fwelnet","ecpc","xrnet")]
#  sapply(table[,-1],function(x) sum(x<table$glmnet))
#  round(100*colMeans(table[,-1]),digits=2)

## ----app_boxplots,echo=TRUE---------------------------------------------------
#  #grDevices::pdf(file=paste0(dir,"/manuscript/figure_ext.pdf"),width=8,height=6,pointsize=15)
#  #grDevices::png(file=paste0(dir,"/manuscript/figure_ext.png"),width=8,height=6,units="in",pointsize=15,res=1200)
#  grDevices::postscript(file=paste0(dir,"/manuscript/figure_ext.eps"),width=8,height=6,pointsize=15,horizontal=FALSE,paper="special")
#  graphics::par(mfrow=c(2,1),mar=c(2.5,2.0,0.5,0.5))
#  for(k in c("grridge","fwelnet")){
#    file <- paste0(dir,"/results/app_",k,".RData")
#    if(!file.exists(file)){plot.new();next}
#    load(file)
#    loss <- as.data.frame(t(sapply(loss,function(x) x$deviance)))
#    colnames(loss) <- gsub(pattern="transreg.",replacement="",x=colnames(loss))
#    loss <- 100*(loss-loss$glmnet)/loss$glmnet
#  
#    temp <- c("exp.sta","exp.sim","iso.sta","iso.sim")
#    name <- c("fwelnet","ecpc","xrnet",temp)
#    graphics::plot.new()
#    graphics::plot.window(xlim=c(0.5,length(name)+0.5),ylim=range(loss,na.rm=TRUE))
#    graphics::abline(h=0,lty=2,col="grey")
#    #graphics::axis(side=1,at=seq_along(name),labels=name,cex.axis=0.7) # original
#    cond <- grepl(pattern="\\.",x=name)
#    graphics::axis(side=1,at=seq_along(name),labels=rep("",times=length(name)))
#    graphics::mtext(side=1,at=seq_along(name)[!cond],text=name[!cond],cex=0.7,line=1)
#    graphics::mtext(side=1,at=seq_along(name)[cond],text=name[cond],cex=0.7,line=0.25)
#    graphics::mtext(side=1,at=mean(seq_along(name)[cond]),text="transreg",cex=0.7,line=1)
#  
#    if(grepl(pattern="grridge",x=k)){at <- seq(from=-10,to=10,by=5)}
#    if(grepl(pattern="fwelnet",x=k)){at <- seq(from=-20,to=20,by=10)}
#    labels <- ifelse(at==0,"0%",ifelse(at<0,paste0(at,"%"),paste0("+",at,"%")))
#    graphics::axis(side=2,cex.axis=0.7,at=at,labels=labels)
#    #graphics::title(ylab="change in metric",line=2.5,cex.lab=0.7)
#    graphics::box()
#    for(i in seq_along(name)){
#      palasso:::.boxplot(loss[,name[i]],at=i,invert=FALSE)
#      graphics::points(x=i,y=mean(loss[,name[i]]),pch=22,col="white",bg="black",cex=0.7)
#    }
#  }
#  grDevices::dev.off()

## ----ncerpd_script,eval=FALSE,echo=TRUE---------------------------------------
#  #<<init>>
#  geno <- read.table(paste0(dir,"/data/vcf_with_pvalue.tab"),header=TRUE)
#  
#  switch <- ifelse(geno$REF==geno$A1_gwas & geno$ALT==geno$A2_gwas,1,
#                   ifelse(geno$REF==geno$A2_gwas & geno$ALT==geno$A1_gwas,-1,0))
#  #prior <- -geno$beta*switch # original effect sizes
#  prior <- log10(geno$p_value)*sign(geno$beta)*switch # pseudo effect sizes
#  pvalue <- geno$p_value
#  
#  # Note: Why are pseudo-effect sizes more suitable as prior effects as compared to original effect sizes?
#  # graphics::plot(x=geno$beta,y=-log10(geno$p_value),xlim=c(-1,1),col=ifelse(stats::p.adjust(geno$p_value)<=0.05,"red","black"))
#  
#  X <- geno[,grepl(pattern="ND",colnames(geno))]
#  X[X=="0/0"] <- 0
#  X[X=="0/1"] <- 1
#  X[X=="1/1"] <- 1
#  X <- sapply(X,as.numeric)
#  X <- t(X)
#  
#  pheno <- read.delim(paste0(dir,"/data/LuxPark_pheno.txt"),sep=" ",header=FALSE)
#  y <- ifelse(pheno$V2==1,0,ifelse(pheno$V2==2,1,NA)); names(y) <- pheno$V1
#  
#  names <- intersect(names(y[!is.na(y)]),rownames(X))
#  X <- X[names,]; y <- y[names]
#  
#  # Note: Are prior effects positively correlated with correlation between outcome and features?
#  # cor <- as.numeric(stats::cor(y,X,method="spearman"))
#  # graphics::plot(x=prior,y=cor,col=ifelse(stats::p.adjust(geno$p_value)<=0.05,"red","black"))
#  # graphics::abline(h=0,lty=2,col="grey")
#  
#  # descriptive statistics
#  sum(p.adjust(pvalue,method="BH")<=0.05)
#  sum(p.adjust(pvalue,method="holm")<=0.05)
#  mean(pvalue<=0.05)
#  dim(X)
#  table(y)
#  
#  # memory reduction
#  cond <- pvalue <= 0.05
#  X <- X[,cond]
#  prior <- prior[cond]
#  pvalue <- pvalue[cond]
#  switch <- switch[cond]
#  
#  save(y,X,prior,pvalue,switch,file=paste0(dir,"/data/app_int_data.RData"))
#  
#  load(paste0(dir,"/data/app_int_data.RData"))
#  power <- seq(from=-2,to=-10,by=-1)
#  cutoff <- 5*10^power
#  frame <- expand.grid(cutoff=cutoff,alpha=0:1,seed=1:10,count=NA)
#  
#  #- - - sequential (start) - - -
#  #loss <- list()
#  #for(i in seq_len(nrow(frame))){
#  #  cat("--- i =",i,"---","\n")
#  #  set.seed(frame$seed[i])
#  #  foldid <- transreg:::.folds(y=y,nfolds.ext=10,nfolds.int=10)
#  #  cond <- switch!=0 & pvalue < frame$cutoff[i]
#  #  loss[[i]] <- transreg:::compare(target=list(y=y,x=X[,cond]),prior=prior[cond],family="binomial",alpha=frame$alpha[i],scale=c("exp","iso"),sign=FALSE,switch=FALSE,select=FALSE,foldid.ext=foldid$foldid.ext,foldid.int=foldid$foldid.int,type.measure=c("deviance","class","auc"),seed=frame$seed[i])
#  #  frame$count[i] <- sum(cond)
#  #}
#  # - - - sequential (end) - - -
#  
#  #- - - parallel (start) - - -
#  frame <- expand.grid(cutoff=cutoff,alpha=0:1,seed=1:10,count=NA)
#  cluster <- snow::makeCluster(8)
#  evaluate <- function(frame,i,switch,pvalue,y,X,prior){
#    set.seed(frame$seed[i])
#    foldid <- transreg:::.folds(y=y,nfolds.ext=10,nfolds.int=10)
#    cond <- switch!=0 & pvalue < frame$cutoff[i]
#    transreg:::compare(target=list(y=y,x=X[,cond]),prior=prior[cond],family="binomial",alpha=frame$alpha[i],scale=c("exp","iso"),sign=FALSE,switch=FALSE,select=FALSE,foldid.ext=foldid$foldid.ext,foldid.int=foldid$foldid.int,type.measure=c("deviance","class","auc"),seed=frame$seed[i])
#  }
#  snow::clusterExport(cl=cluster,list=c("evaluate","frame","switch","pvalue","y","X","prior"))
#  loss <- snow::parSapply(cl=cluster,X=seq_len(nrow(frame)),FUN=function(i) evaluate(frame=frame,i=i,switch=switch,pvalue=pvalue,y=y,X=X,prior=prior),simplify=FALSE)
#  #- - - parallel (end) - - -
#  
#  save(frame,loss,file=paste0(dir,"/results/app_int.RData"))
#  writeLines(text=capture.output(utils::sessionInfo(),cat("\n"),
#        sessioninfo::session_info()),con=paste0(dir,"/results/info_app_int.txt"))

## ----ncerpd_plot,echo=TRUE----------------------------------------------------
#  #<<init>>
#  
#  plotter <- function(table,cutoff,number,horizontal=FALSE){
#    graphics::par(mfrow=c(2,2),mar=c(3,1.8,1.0,0.9))
#    for(scale in c("exp","iso")){
#      for(alpha in c("0","1")){
#        graphics::plot.new()
#        graphics::plot.window(xlim=range(log(cutoff)),ylim=range(table))
#        graphics::box()
#        graphics::title(main=paste(ifelse(alpha==0,"ridge",ifelse(alpha==1,"lasso",NA)),"-",scale),cex.main=1,line=0.2)
#        on <- rep(c(TRUE,FALSE),length.out=length(cutoff))
#        graphics::axis(side=1,at=log(cutoff),labels=rep("",times=length(on)),cex.axis=0.7)
#        graphics::axis(side=1,at=log(cutoff)[on],labels=paste0(cutoff[on],"\n","(",number[on],")"),cex.axis=0.7)
#        graphics::axis(side=2,cex.axis=0.7)
#        if(horizontal){
#          graphics::abline(h=0.5,col="grey",lty=2)
#          #graphics::abline(h=unique(table[["mean"]][,alpha]),col="grey",lty=2)
#        }
#        for(i in 1:3){
#          for(method in c("glmnet",paste0("transreg.",scale,c(".sta",".sim")),"naive")){
#            lty <- switch(method,"mean"=1,"glmnet"=1,"transreg.exp.sta"=2,"transreg.exp.sim"=2,"transreg.iso.sta"=2,"transreg.iso.sim"=2,"naive"=3)
#            col <- switch(method,"mean"="grey","glmnet"="black","transreg.exp.sta"=rgb(0.2,0.2,1),"transreg.iso.sta"=rgb(0.2,0.2,1),"transreg.exp.sim"=rgb(0,0,0.6),"transreg.iso.sim"=rgb(0,0,0.6),"naive"="red")
#            y <- table[[method]][,alpha]
#            x <- log(as.numeric(names(y)))
#            if(i==1){graphics::lines(x=x,y=y,col=col,lty=lty)}
#            if(i==2){graphics::points(x=x,y=y,col="white",pch=16)}
#            if(i==3){graphics::points(x=x,y=y,col=col)}
#          }
#        }
#      }
#    }
#  }
#  
#  load(paste0(dir,"/data/app_int_data.RData"))
#  load(paste0(dir,"/results/app_int.RData"))
#  frame <- frame[seq_along(loss),colnames(frame)!="seed"]
#  cutoff <- unique(frame$cutoff)
#  number <- unique(sapply(loss,function(x) x$p))
#  
#  auc <- as.data.frame(t(sapply(loss,function(x) x$auc)))
#  table <- lapply(auc,function(x) tapply(X=x,INDEX=list(frame$cutoff,frame$alpha),FUN=function(x) mean(x)))
#  
#  #grDevices::pdf(file=paste0(dir,"/manuscript/figure_int.pdf"),width=8,height=6,pointsize=15)
#  #grDevices::png(file=paste0(dir,"/manuscript/figure_int.png"),width=8,height=6,units="in",pointsize=15,res=1200)
#  grDevices::postscript(file=paste0(dir,"/manuscript/figure_int.eps"),width=8,height=6,pointsize=15,horizontal=FALSE,paper="special")
#  plotter(table,cutoff,number,horizontal=TRUE)
#  grDevices::dev.off()

## ----ncerpd_auc,eval=FALSE,echo=TRUE,fig.cap="Box plots of $10\\,000$ \\textsc{auc}s ($y$-axis) at different sample sizes ($x$-axis), namely either $50+50$ ('small') or $766+790$ ('large'). Each \\textsc{auc} is calculated from a binary outcome and random predicted probabilities (standard uniform distribution). The red lines separate the top 5\\% of the \\textsc{auc}s from the bottom 95\\% of the \\textsc{auc}s."----
#  
#  #--- empirical computation of confidence interval ---
#  
#  set.seed(1)
#  auc <- list()
#  n <- c("small","large")
#  for(i in seq_along(n)){
#    auc[[i]] <- numeric()
#    for(j in 1:10000){
#      if(n[i]=="small"){
#        y <- rep(c(0,1),times=c(50,50))
#      }
#      if(n[i]=="large"){
#        y <- rep(c(0,1),times=c(766,790))
#      }
#      x <- stats::runif(n=length(y),min=0,max=1)
#  
#      auc[[i]][j] <- pROC::auc(response=y,predictor=x,direction="<",levels=c(0,1))
#    }
#  }
#  q <- sapply(auc,function(x) quantile(x,probs=0.95))
#  graphics::par(mar=c(3.5,3.5,1,1))
#  graphics::plot.new()
#  graphics::plot.window(xlim=c(0.5,length(n)+0.5),ylim=range(auc))
#  graphics::box()
#  graphics::axis(side=1,at=seq_along(n),labels=n)
#  graphics::axis(side=2)
#  for(i in seq_along(n)){
#    graphics::boxplot(x=auc[[i]],at=i,add=TRUE)
#  }
#  graphics::abline(h=0.5)
#  graphics::title(xlab="sample size",ylab="AUC",line=2.5)
#  graphics::segments(x0=seq_along(n)-0.2,x1=seq_along(n)+0.2,y0=q,col="red",lwd=2)
#  graphics::text(x=seq_along(n)-0.2,y=q,labels=round(q,digits=3),pos=2,cex=0.5,col="red")
#  q
#  
#  #--- analytical calculation of confidence interval ---
#  
#  # This code is based on the website "Real Statistics using Excel" from Charles Zaiontz, https://real-statistics.com/descriptive-statistics/roc-curve-classification-table/auc-confidence-interval/).
#  
#  var_AUC <- function(x,n1,n2) {
#    q1 = x/(2-x)
#    q2 = 2*x^2/(1+x)
#    var = (x*(1-x) +(n1-1)*(q1-x^2) +(n2-1)*(q2-x^2))/(n1*n2)
#  }
#  round(0.5 + stats::qnorm(p=0.95)*sqrt(var_AUC(0.5,n1=50,n2=50)),digits=3)
#  round(0.5 + stats::qnorm(p=0.95)*sqrt(var_AUC(0.5,n1=766,n2=790)),digits=3)

## ----extra_time,eval=FALSE,echo=FALSE-----------------------------------------
#  #--- This code chunk is not included in the manuscript! ---
#  
#  # Synthetic example with measurement of computation time.
#  
#  set.seed(1)
#  n0 <- 100
#  n1 <- 5
#  n <- n0+n1
#  p <- 1000
#  m <- 3
#  data <- list()
#  for(i in 1:(m+1)){
#    data[[i]] <- list()
#    data[[i]]$x <- matrix(stats::rnorm(n*p),nrow=n,ncol=p)
#    data[[i]]$y <- stats::rbinom(n=n,size=1,prob=0.5)
#  }
#  source <- data[1:m]
#  names(source) <- paste0("s",1:m)
#  target <- data[[m+1]]
#  prior <- matrix(stats::rnorm(p*m),nrow=p,ncol=m)
#  alpha <- 1
#  foldid.ext <- rep(c(0,1),times=c(n0,n1))
#  nfolds.ext <- 1
#  alpha <- 1
#  
#  time <- transreg:::compare(target=target,source=source,z=abs(prior),family="binomial",alpha=alpha,xrnet=TRUE,foldid.ext=foldid.ext,nfolds.ext=nfolds.ext,alpha.prior=alpha)$time
#  
#  # As transreg::compare performs exponential and isotonic calibration, we also train transreg with the default parameters.
#  start <- Sys.time()
#  test <- transreg::transreg(y=target$y[seq_len(n0)],X=target$x[seq_len(n0),],prior=prior,family="binomial",alpha=alpha)
#  end <- Sys.time()
#  time["transreg.single"] <- difftime(time1=end,time2=start,units="secs")
#  
#  paste0(paste0(names(time),": ",round(time/time["glmnet"],digits=2)),collapse=", ")

## ----extra_xrnet,echo=TRUE,eval=FALSE-----------------------------------------
#  #--- This code chunk is not included in the manuscript! ---
#  
#  # The following chunk performs the additional simulation study with either linearly or non-linearly related prior effects for the comparison of transreg and xrnet.
#  
#  set.seed(1)
#  
#  temp <- matrix(data=NA,nrow=10,ncol=2,dimnames=list(NULL,c("transreg","xrnet")))
#  mse <- list(linear=temp,nonlinear=temp)
#  
#  for(i in c("linear","nonlinear")){
#    for(j in 1:10){
#  
#      # simulate data
#      n0 <- 100; n1 <- 10000; n <- n0 + n1; p <- 2000
#      X <- matrix(stats::rnorm(n*p),nrow=n,ncol=p)
#      beta <- stats::rnorm(n=p)*stats::rbinom(n=p,size=1,prob=0.05)
#      y <- stats::rnorm(n=n,mean=X %*% beta,sd=1) #sd(X %*% beta)
#  
#      # relation between prior effects and true effects
#      temp <- beta + stats::rnorm(n=p)*stats::rbinom(n=p,size=1,prob=0.01)
#      # temp <- beta + stats::rnorm(p,sd=0.1) # for comparison
#      if(i=="linear"){
#        prior <- temp
#      } else if(i=="nonlinear"){
#        prior <- sign(temp)*abs(temp)^2
#      }
#  
#      # hold-out
#      y_hat <- list()
#      foldid <- rep(c(0,1),times=c(n0,n1))
#  
#      # transfer learning with transreg
#      model <- transreg::transreg(y=y[foldid==0],X=X[foldid==0,],prior=prior)
#      y_hat$transreg <- predict(model,newx=X[foldid==1,])
#  
#      # transfer learning with xrnet
#      model <- xrnet::tune_xrnet(x=X[foldid==0,],y=y[foldid==0],external=as.matrix(prior,ncol=1))
#      y_hat$xrnet <- stats::predict(model,newdata=X[foldid==1,])
#  
#      # mean squared error (MSE)
#      mse[[i]][j,] <- sapply(y_hat,function(x) mean((x-y[foldid==1])^2))
#  
#    }
#  }
#  
#  # linear scenario
#  sum(mse$linear[,"xrnet"] < mse$linear[,"transreg"])
#  stats::wilcox.test(x=mse$linear[,"xrnet"],y=mse$linear[,"transreg"],paired=TRUE)$p.value
#  
#  # non-linear scenario
#  sum(mse$nonlinear[,"transreg"] < mse$nonlinear[,"xrnet"])
#  stats::wilcox.test(x=mse$nonlinear[,"transreg"],y=mse$nonlinear[,"xrnet"],paired=TRUE)$p.value

## ----extra_devel,eval=FALSE,echo=FALSE----------------------------------------
#  #--- This code chunk is under development! ---
#  
#  # - - - multi-split test - - -
#  
#  tester <- function(y,x){
#    foldid <- x$foldid
#    pred <- x$pred
#    limit <- 1e-06
#    pred[pred < limit] <- limit
#    pred[pred > 1 - limit] <- 1 - limit
#    res <- -2 * (y * log(pred) + (1 - y) * log(1 - pred))
#    method <- paste0("transreg.",c("exp.sta","exp.sim","iso.sta","iso.sim"))
#    pvalue <- matrix(NA,nrow=10,ncol=length(method),dimnames=list(NULL,method))
#    for(i in seq_len(10)){
#      for(j in seq_along(method)){
#        pvalue[i,j] <- stats::wilcox.test(x=res[foldid==i,"glmnet"],y=res[foldid==i,method[j]],paired=TRUE,alternative="greater")$p.value
#      }
#    }
#    return(pvalue)
#  }
#  
#  pvalue <- lapply(loss,function(x) tester(y=y,x=x))
#  alpha <- c(0,1)
#  method <- paste0("transreg.",c("exp.sta","exp.sim","iso.sta","iso.sim"))
#  median <- array(NA,dim=c(length(alpha),length(cutoff),length(method)),dimnames=list(alpha,cutoff,method))
#  for(i in seq_along(alpha)){
#    for(j in seq_along(cutoff)){
#        median[i,j,] <- apply(do.call(what="rbind",args=pvalue[frame$alpha==alpha[i] & frame$cutoff==cutoff[j]]),2,median)
#    }
#  }
#  1*(median<=0.05)
#  
#  #- - - estimation stability - - -
#  
#  stability <- function(x,mode="cor"){
#    if(mode=="cor"){
#      if(all(is.na(x))){
#        return(1)
#      }
#      if(sd(x,na.rm=TRUE)==0){
#        return(1)
#      }
#      cor <- stats::cor(x,method="spearman")
#      cor[is.na(cor)] <- 0
#      diag(cor) <- NA
#      index <- median(cor,na.rm=TRUE)
#    } else if(mode=="rank"){
#      top_sep <- apply(x,2,function(x) order(abs(x),decreasing=TRUE)[1:10])
#      sign_sep <- matrix(sign(x)[cbind(as.numeric(top_sep),rep(1:ncol(x),each=10))],nrow=10,ncol=10)
#      top_all <- order(abs(rowMeans(x)),decreasing=TRUE)[1:10]
#      sign_all <- sign(rowMeans(x))[top_all]
#      sep <- top_sep * sign_sep
#      all <- top_all * sign_all
#      index <- mean(apply(sep,2,function(x) mean(x %in% all)))
#    }
#    return(index)
#  }
#  
#  value <- as.data.frame(t(sapply(loss,function(x) sapply(x$coef,function(x) stability(x,mode="rank")))))
#  table <- lapply(value,function(x) tapply(X=x,INDEX=list(frame$cutoff,frame$alpha),FUN=function(x) mean(x)))
#  plotter(table,cutoff,number)

## ----names,eval=FALSE,echo=FALSE----------------------------------------------
#  # code for reformatting list of consortium members
#  list <- "Alexander HUNDT 2, Alexandre BISDORFF 5, Amir SHARIFY 2, Anne GRÜNEWALD 1, Anne-Marie HANFF 2, Armin RAUSCHENBERGER 1, Beatrice NICOLAI 3, Brit MOLLENHAUER 12, Camille BELLORA 2, Carlos MORENO 1, Chouaib MEDIOUNI 2, Christophe TREFOIS 1, Claire PAULY 1,3, Clare MACKAY 10, Clarissa GOMES 1, Daniela BERG 11, Daniela ESTEVES 2, Deborah MCINTYRE 2, Dheeraj REDDY BOBBILI 1, Eduardo ROSALES 2, Ekaterina SOBOLEVA 1, Elisa GÓMEZ DE LOPE 1, Elodie THIRY 3, Enrico GLAAB 1, Estelle HENRY 2, Estelle SANDT 2, Evi WOLLSCHEID-LENGELING 1, Francoise MEISCH 1, Friedrich MÜHLSCHLEGEL 4, Gaël HAMMOT 2, Geeta ACHARYA 2, Gelani ZELIMKHANOV 3, Gessica CONTESOTTO 2, Giuseppe ARENA 1, Gloria AGUAYO 2, Guilherme MARQUES 2, Guy BERCHEM 3, Guy FAGHERAZZI 2, Hermann THIEN 2, Ibrahim BOUSSAAD 1, Inga LIEPELT 11, Isabel ROSETY 1, Jacek JAROSLAW LEBIODA 1, Jean-Edouard SCHWEITZER 1, Jean-Paul NICOLAY 19, Jean-Yves FERRAND 2, Jens SCHWAMBORN 1, Jérôme GRAAS 2, Jessica CALMES 2, Jochen KLUCKEN 1,2,3, Johanna TROUET 2, Kate SOKOLOWSKA 2, Kathrin BROCKMANN 11, Katrin MARCUS 13, Katy BEAUMONT 2, Kirsten RUMP 1, Laura LONGHINO 3, Laure PAULY 1, Liliana VILAS BOAS 3, Linda HANSEN 1,3, Lorieza CASTILLO 2, Lukas PAVELKA 1,3, Magali PERQUIN 2, Maharshi VYAS 1, Manon GANTENBEIN 2, Marek OSTASZEWSKI 1, Margaux SCHMITT 2, Mariella GRAZIANO 17, Marijus GIRAITIS 2,3, Maura MINELLI 2, Maxime HANSEN 1,3, Mesele VALENTI 2, Michael HENEKA 1, Michael HEYMANN 2, Michel MITTELBRONN 1,4, Michel VAILLANT 2, Michele BASSIS 1, Michele HU 8, Muhammad ALI 1, Myriam ALEXANDRE 2, Myriam MENSTER 2, Nadine JACOBY 18, Nico DIEDERICH 3, Olena TSURKALENKO 2, Olivier TERWINDT 1,3, Patricia MARTINS CONDE 1, Patrick MAY 1, Paul WILMES 1, Paula Cristina LUPU 2, Pauline LAMBERT 2, Piotr GAWRON 1, Quentin KLOPFENSTEIN 1, Rajesh RAWAL 1, Rebecca TING JIIN LOO 1, Regina BECKER 1, Reinhard SCHNEIDER 1, Rejko KRÜGER 1,2,3, Rene DONDELINGER 5, Richard WADE-MARTINS 9, Robert LISZKA 14, Romain NATI 3, Rosalina RAMOS LIMA 2, Roseline LENTZ 7, Rudi BALLING 1, Sabine SCHMITZ 1, Sarah NICKELS 1, Sascha HERZINGER 1, Sinthuja PACHCHEK 1, Soumyabrata GHOSH 1, Stefano SAPIENZA 1, Sylvia HERBRINK 6, Tainá MARQUES 1, Thomas GASSER 11, Ulf NEHRBASS 2, Valentin GROUES 1, Venkata SATAGOPAM 1, Victoria LORENTZ 2, Walter MAETZLER 15, Wei GU 1, Wim AMMERLANN 2, Yohan JAROZ 1, Zied LANDOULSI 1"
#  list <- strsplit(list,split=", ")[[1]]
#  number <- gsub(pattern="[^0-9,]",replacement="",x=list)
#  names <- gsub(pattern="[0-9,]",replacement="",x=list)
#  for(i in seq_along(names)){
#    if(substring(text=names[i],first=1,last=1)==" "){
#      names[i] <- substring(text=names[i],first=2,last=nchar(names[i]))
#    }
#    if(substring(text=names[i],first=nchar(names[i]),last=nchar(names[i]))==" "){
#      names[i] <- substring(text=names[i],first=1,last=nchar(names[i])-1)
#    }
#  }
#  names <- strsplit(names,split=" ")
#  for(i in seq_along(names)){
#    cond <- grepl(pattern="[a-z]",x=names[[i]])
#    first <- paste0(names[[i]][cond],collapse=" ")
#    last <- paste0(tolower(names[[i]][!cond]),collapse=" ")
#    names[[i]] <- paste0(first," \textsc{",last,"}","$^{",number[i],"}$")
#  }
#  paste0(names,collapse=", ")
#  inst <- "1 Luxembourg Centre for Systems Biomedicine, University of Luxembourg, Esch-sur-Alzette, Luxembourg; 2 Luxembourg Institute of Health, Strassen, Luxembourg; 3 Centre Hospitalier de Luxembourg, Strassen, Luxembourg; 4 Laboratoire National de Santé, Dudelange, Luxembourg; 5 Centre Hospitalier Emile Mayrisch, Esch-sur-Alzette, Luxembourg; 6 Centre Hospitalier du Nord, Ettelbrück, Luxembourg; 7 Parkinson Luxembourg Association, Leudelange, Luxembourg; 8 Oxford Parkinson's Disease Centre, Nuffield Department of Clinical Neurosciences, University of Oxford, Oxford, UK; 9 Oxford Parkinson's Disease Centre, Department of Physiology, Anatomy and Genetics, University of Oxford, Oxford, UK; 10 Oxford Centre for Human Brain Activity, Wellcome Centre for Integrative Neuroimaging, Department of Psychiatry, University of Oxford, Oxford, UK; 11 Center of Neurology and Hertie Institute for Clinical Brain Research, Department of Neurodegenerative Diseases, University Hospital Tübingen, Tübingen, Germany; 12 Paracelsus-Elena-Klinik, Kassel, Germany; 13 Ruhr-University of Bochum, Bochum, Germany; 14 Westpfalz-Klinikum GmbH, Kaiserslautern, Germany; 15 Department of Neurology, University Medical Center Schleswig-Holstein, Kiel, Germany; 16 Department of Neurology Philipps, University Marburg, Marburg, Germany; 17 Association of Physiotherapists in Parkinson's Disease Europe, Esch-sur-Alzette, Luxembourg; 18 Private practice, Ettelbruck, Luxembourg; 19 Private practice, Luxembourg, Luxembourg"
#  list <- strsplit(inst,split="; ")[[1]]
#  number <- gsub(pattern="[^0-9]",replacement="",x=list)
#  name <- gsub(pattern="[0-9]",replacement="",x=list)
#  name <- substring(name,first=2,last=nchar(name))
#  paste(paste0("$^{",number,"}$",name),collapse=", ")

## ----sessionInfo,echo=FALSE,results="asis"------------------------------------
#  info <- devtools::session_info()
#  knitr::kable(data.frame(setting=names(info[[1]]),value=unlist(info[[1]]),row.names=NULL))
#  knitr::kable(info[[2]][,c("package","loadedversion","date","source")])

