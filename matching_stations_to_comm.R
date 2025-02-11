
# Purpose -----------------------------------------------------------------

# This R script is the basic set up for matching any station coordinate 
# (latitude and longitude) data with the Chicago community. 
# Can be referenced in the divvy_community_station_stats.R file too.

# Load Packages -----------------------------------------------------------

library(tidyverse)
library(rgeos)
library(sp)
library(rgdal)
library(magrittr)
library(raster)
library(sf)

#First, read in the data with the coordinates you want to match to geographical areas (bike data, traffic stops, etc...)
point_data <- read_csv("data/divvy2013_sample.csv")
point_data <- point_data %>% 
  dplyr::select(-1) %>% 
  janitor::clean_names() 

# Then read in the shape file that outlines your geographic units (neighborhoods, census tracts, etc...)
geo_data <- read_sf("data/geo_export_279165a1-c897-4e25-b141-d5fc4a4996ec.shp")

# assign_if_not_in should be a string that is using in the geographical area column if the point from point_data does
# not fall into any of the geographical areas.  For example, if you are looking at bike stations and neighborhoods,
# if the station is in Evanston the neighborhood column will contain assign_if_not_in for that row
assign_if_not_in <- c("Not Listed")

# long_lat_vec should be a vector of the names of your longitude and latitude columns, in that order. 
long_lat_vec = c("longitude", "latitude")

# mapping function
map_point_to_geo <- function(point_data, geo_data, community, assign_if_not_in, long_lat_vec){
  
  point_data_sf <- st_as_sf(point_data, coords = long_lat_vec, crs = st_crs(geo_data))
  
  #intersection column 
  point_data <- point_data_sf %>% 
    mutate(intersection = as.integer(st_intersects(geometry, geo_data)),
           community = if_else(is.na(intersection), '', geo_data[[community]][intersection])) 
  
  point_data_done <- tibble(point_data) %>%
    mutate(community = ifelse(is.na(intersection), assign_if_not_in, community)) %>%
    dplyr::select(-intersection)
  
  return(point_data_done)
}

#calling function to map data points to the community they belong in
final_data <- map_point_to_geo(point_data, geo_data, "community", "None", c("longitude", "latitude"))

# View(final_data)

# print processed data to a csv
write_csv(final_data, "data/processed/station_hist_community_measures.csv")

