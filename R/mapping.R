#' @description Function to map / prep zip files into information mapping
#' @param zip_path your zip file location
#' @param metadata_type metadata type for reference point
#' @inherit
#' @import logger
#' @import dplyr
#' @import data.table
#' @import purrr
#' @importFrom magrittr %>%
#' @importFrom utils unzip
#' @importFrom stats setNames
map_metadata_staging_zip_file <- function(zip_path, metadata_type) {
  temp <- unzip(zip_path, list = TRUE)$Name
  temp <- grep("csv$", temp, value = TRUE)


  # path to your zip file
  output_list <- purrr::map(temp, function(c){
    sz <- stringr::str_split(c , "/") %>%
      unlist() %>%
      length()
    if(sz > 1){
      return(NULL)
    }else{
      return(c)
    }}
  ) %>%
    purrr::compact() %>%
    purrr::discard(is.null)

  naming_filename <- output_list %>%
    purrr::map_chr(~paste0(tools::file_path_sans_ext(.x), '__staging_filename'))
  naming_df <- output_list %>%
    purrr::map_chr(~paste0(tools::file_path_sans_ext(.x), '__staging_dataframe'))

  output_mapping_filename <- output_list %>%
    setNames(naming_filename)

  output_mapping_df <- purrr::map(output_mapping_filename, function(fn){
    fread(
      unzip(zip_path, fn, exdir = glue::glue('/tmp/{metadata_type}')),
      colClasses=c("hhid"="character")
    ) %>%
      tibble::as_tibble()
  }) %>%
    setNames(naming_df)
  output_mapping <- c(output_mapping_df)
  output_mapping$metadata_type <- metadata_type
  output_mapping$file_list <- output_list %>% unlist()
  return(output_mapping)
}
