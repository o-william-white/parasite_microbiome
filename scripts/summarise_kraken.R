#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

library(tidyverse)
library(reshape2)

# args
input_path  = args[1]
output_path = args[2]

# list report files
files <- list.files(input_path, full.names = TRUE, pattern = "*_report.txt")

# print info
cat(paste("Input path:", input_path, "\n"))
cat(paste("Output path:", output_path, "\n"))
cat(paste(length(files), "report files identified\n"))

# table function
tfunc <- function(f) {
  
  # get run name
  run <- gsub("_report.txt","", basename(f))
  
  # read table
  dat <- read.table(f, sep = "\t", quote = "",
                    col.names = c("pct", "fragments_clade", "fragments_taxon", "rank", "ncbi_id", "scientific_name"))
  
  # rm leading spaces from scientific name column
  dat$scientific_name <- gsub(" ", "", dat$scientific_name)
  
  # filter for genus records where pct not 0
  # remove host, duplicate rows of uncultured found
  dat <- arrange(dat, desc(pct)) %>%
    filter(rank == "G",
           pct > 0,
           scientific_name != "uncultured",
           scientific_name != "Homo") %>%
    select("scientific_name", "pct")
  
  # select the top 20
  dat <- head(dat, n = 20)
  
  # rename pct column
  colnames(dat)[2] <- run
  
  # return dat
  return(dat)
  
}

# read tables into list
cat("Reading reports\n")
t_list <- lapply(files, tfunc)

# count number of 20 most frequent genera across runs
cat("Counting the 20 most frequent genera across runs\n")
list_scientific_names <- lapply(t_list, function(x) x$scientific_name)
vector_scientific_names <- unlist(list_scientific_names)
count_scientific_names <- sort(table(vector_scientific_names), decreasing = T)
count_scientific_names_df <- head(count_scientific_names, n=20) %>%
  as.data.frame() %>%
  rename("Genera" = "vector_scientific_names",
         "Count" = "Freq")

# full join
cat("Joining reports\n")
dat_joined <- reduce(t_list, full_join, by=c("scientific_name"))

# convert NAs to zero
dat_joined [ is.na(dat_joined) ] <- 0

# describe data
cat(paste("Joined table has", nrow(dat_joined), "taxa across", ncol(dat_joined)-1, "runs\n"))

# convert to long
dat_long <- melt(dat_joined, id.vars = "scientific_name")

# calculate mean and median pct per genus
dat_summary <- dat_long %>% 
  group_by(scientific_name) %>% 
  summarise(mean_pct = mean(value), 
            median_pct = median(value)) %>%
  arrange(desc(median_pct))

data.frame(dat_summary)

# calculate log
dat_long$value_log = log(dat_long$value + 0.001)

# set levels of dat_joined
dat_long$scientific_name <- factor(dat_long$scientific_name, levels = c(dat_summary$scientific_name))

# Create output dir
if(!dir.exists(output_path)) {
  cat("Creating output directory\n")
  dir.create(output_path)
} else {
  cat("Output directory exists\n")
}

cat("Writing counts plot\n")
png(paste0(output_path, "/plot_count.png"), height = 15, width = 20, units = "cm", res = 300)
ggplot(count_scientific_names_df, aes(y = Genera, x = Count)) + geom_bar(stat ="identity") +
  theme(axis.text.y = element_text(face = "italic"))
dev.off()

# write directory
cat("Writing table\n")
write.table(dat_joined, paste0(output_path, "/table_join.txt"), sep = "\t", quote = F, col.names = T, row.names = F)

# define plot height and width
height_scale = 2.6
width_scale = 2.22
height_cm = nrow(dat_joined) / height_scale
width_cm  = ncol(dat_joined) / width_scale

cat("Writing heatmaps\n")
png(paste0(output_path, "/plot_heatmap.png"), height = height_cm, width = width_cm, units = "cm", res = 300)
ggplot(data = dat_long, aes(x = variable, y = scientific_name, fill = value)) +
  geom_tile(colour = "gray") +
  scale_fill_gradient(low="white", high = "darkred") + 
  labs(x = "Run",
       y = "Genus",
       fill = "Pct") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
        axis.text.y = element_text(face = "italic"))
dev.off()

png(paste0(output_path, "/plot_heatmap_log.png"), height = height_cm, width = width_cm, units = "cm", res = 300)
ggplot(data = dat_long, aes(x = variable, y = scientific_name, fill = value_log)) +
  geom_tile(colour = "gray") +
  scale_fill_gradient(low="white", high = "darkred") +
  labs(x = "Run",
       y = "Genus",
       fill = "Pct") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
        axis.text.y = element_text(face = "italic"))
dev.off()


