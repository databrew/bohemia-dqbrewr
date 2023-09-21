get_prev_healthecon_household_data <- function(){
  tbl <- tryCatch({
    cloudbrewr::aws_s3_get_table(
      bucket = 'bohemia-lake-db',
      key = 'metadata/healthecon_household_data/household_data.csv')
  }, error = function(e){
    logger::log_error('Error fetching file, returning empty tibble')
    return(tibble::tibble())
  })
  return(tbl)
}

get_prev_healthecon_individual_data <- function() {
  tbl <- tryCatch({
    cloudbrewr::aws_s3_get_table(
      bucket = 'bohemia-lake-db',
      key = 'metadata/healthecon_individual_data/individual_data.csv')
  }, error = function(e){
    logger::log_error('Error fetching file, returning empty tibble')
    return(tibble::tibble())
  })
  return(tbl)
}


check_v0_household_healthecon_status <- function(household_data) {
  # this needs to be all out
  err <- household_data %>%
    dplyr::filter(visit_flag == 'V0') %>%
    dplyr::filter(hecon_hh_status != 'out') %>%
    dplyr::mutate(error_type = 'v0_healthecon_status_not_all_out') %>%
    dplyr::select(key = 'hhid',
                  value = hhid,
                  error_type)


  if(nrow(err) == 0){
    logger::log_success(glue::glue('{green("Healthecon status is all OUT for V0 \u2713")}'))
    return(tibble::tibble())
  }else{
    logger::log_error(glue::glue('{red("Healthecon status is all OUT for V0 \u2717")}'))
    return(err)
  }
}


check_v1_household_healthecon_status <- function(household_data) {
# this needs to be either in or out
}

check_v2_to_v5_household_healthecon_status <- function(household_data) {
# IF START FROM IN in V1: EITHER IN OR EOS
# IF START FROM OUT in V1: JUST OUT
}



#' Entry function for checking healtheconomics metadata
#' @export
#' @description this function will run all the necessary checks for health economics metadata.
#' @importFrom magrittr %>%
#' @import logger
#' @import dplyr
#' @import purrr
#' @param zip_path this is where your zip file is located locally
#' @return returns a `check_results_obj`
check_healthecon <- function(zip_path) {

  # error status
  zip_error_status <- FALSE

  # mapper object
  map_obj <- map_metadata_staging_zip_file(zip_path, metadata_type = 'healthecon')

  # check zip file submission
  zip_error_status <- check_zip_n_files(map_obj, n_files = 2)
  zip_error_status <- check_zip_files_naming_validity(map_obj, file_list = c('household_data.csv', 'individual_data.csv'))

  if(zip_error_status) {
    logger::log_error('Zip submission does not fulfill criteria, skipping data assessment until fix is made')

  } else {
    # DO DATA ASSESSMENT
    # get staging and prod datasets
    staging_individual_data <- map_obj$individual_data__staging_dataframe %>%
      dplyr::select(-fullname_dob, -fullname_id, -hecon_name) %>%
      replace(is.na(.), '')
    staging_household_data <- map_obj$household_data__staging_dataframe %>%
      get_visit_flag() %>%
      dplyr::select(-roster, -hecon_members, -visits_done) %>%
      replace(is.na(.), '')

    # check if household is out then individual should be out too
    err_df <- dplyr::bind_rows(
      check_v0_household_healthecon_status(staging_household_data),
      check_out_status(staging_household_data,
                       staging_individual_data,
                       'hecon_hh_status',
                       'starting_hecon_status'),
      check_eos_status(staging_household_data,
                       staging_individual_data,
                       'hecon_hh_status',
                       'starting_hecon_status')
    )

    output_list <- list()
    output_list$err_df <- err_df
    output_list$output_map <- list(
        list(
          output_filename = '/tmp/individual_data.csv',
          curr_s3_key = 'bohemia_prod/metadata_healthecon_individual_data/individual_data.csv',
          hist_s3_key = 'bohemia_prod/metadata_healthecon_individual_data_hist/run_date={run_date}/individual_data.csv',
          bucket = 'bohemia-lake-db',
          data = staging_individual_data),
        list(
          output_filename = '/tmp/household_data.csv',
          curr_s3_key = 'bohemia_prod/metadata_healthecon_household_data/household_data.csv',
          hist_s3_key = 'bohemia_prod/metadata_healthecon_household_data_hist/run_date={run_date}/household_data.csv',
          bucket = 'bohemia-lake-db',
          data = staging_household_data)
    )
    return(output_list)
  }
}
