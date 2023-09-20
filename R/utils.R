#' Check naming in zip file
#'
#' @param map object from map_metadata_staging_zip_file
#' @import crayon
#' @return TRUE if ERROR is intentionally captured, FALSE if passed the test
check_zip_files_naming_validity <- function(map_obj, ...) {
  tryCatch({
    dot_args <- list(...)
    if(setequal(map_obj$file_list, dot_args$file_list)){
      logger::log_success(glue::glue('{green("Valid filenames \u2713")}'))
      return(FALSE)
    }else{
      logger::log_error(glue::glue('{red("Valid filenames \u2717")}'))
      return(TRUE)
    }
  }, error = function(e){
    logger::log_info('check_files_naming_validity internal Package Error\nMessage:')
    logger::log_error(e$message)
    stop()
  })
}


#' Check number of contents in a zip file
#'
#' @import crayon
#' @param map object from map_metadata_staging_zip_file
#' @return TRUE if ERROR is intentionally captured, FALSE if passed the test
check_zip_n_files <- function(map_obj, ...) {
  tryCatch({
    dot_args <- list(...)
    if(setequal(length(map_obj$file_list), dot_args$n_files)){
      logger::log_success(glue::glue('{green("Valid number of files \u2713")}'))
      return(FALSE)
    }else{
      logger::log_error(glue::glue('{red("Valid number of files \u2717")}'))
      return(TRUE)
    }
  }, error = function(e){
    logger::log_info('check_n_files internal Package Error\nMessage:')
    logger::log_error(e$message)
    stop()
  })
}


#' Check OUT status
#' @import crayon
#' @description Check if household is out then all individuals in that household needs to be out
check_out_status <- function(household_data,
                             individual_data,
                             household_data_status,
                             individual_data_status) {
  # IF HOUSEHOLD OUT THEN ALL INDIVIDUAL NEEDS TO BE OUT
  out_hhid <- household_data %>%
    dplyr::filter(!!sym(household_data_status) == 'out') %>% .$hhid

  err <- individual_data %>%
    dplyr::filter(hhid %in% out_hhid) %>%
    dplyr::filter(!!sym(individual_data_status) != 'out') %>%
    dplyr::mutate(error_type = 'household_out_individual_not_out') %>%
    dplyr::select(key = 'extid',
                  value = extid,
                  error_type)


  if(nrow(err) == 0){
    logger::log_success(glue::glue('{green("Individual Healthecon Status is OUT when hhid is OUT \u2713")}'))
    return(tibble::tibble())
  }else{
    logger::log_error(glue::glue('{red("Individual Healthecon Status is OUT when hhid is OUT \u2717")}'))
    return(err)
  }
}

#' Check EOS status
#' @import crayon
#' @description Check if household is eos then all individuals in that household needs to be eos
check_eos_status <- function(household_data,
                             individual_data,
                             household_data_status,
                             individual_data_status) {
  # IF HOUSEHOLD EOS THEN ALL INDIVIDUAL NEEDS TO BE EOS
  eos_hhid <- household_data %>%
    dplyr::filter(!!sym(household_data_status) == 'eos') %>% .$hhid

  err <- individual_data %>%
    dplyr::filter(hhid %in% eos_hhid) %>%
    dplyr::filter(!!sym(individual_data_status) != 'eos') %>%
    dplyr::mutate(error_type = 'household_eos_individual_not_eos') %>%
    dplyr::select(key = 'extid',
                  value = extid,
                  error_type)


  if(nrow(err) == 0){
    logger::log_success(glue::glue('{green("Individual Healthecon Status is EOS when hhid is EOS \u2713")}'))
    return(tibble::tibble())
  }else{
    logger::log_error(glue::glue('{red("Individual Healthecon Status is EOS when hhid is EOS \u2717")}'))
    return(err)
  }

}


#' Get visit flag
#' @description Get most recent visit flags (to parse out the comma separated colum visits_done)
get_visit_flag <- function(data) {
  tryCatch({
    data %>%
      dplyr::mutate(visit_flag = ifelse(is.na(visits_done), 'V0')) %>%
      dplyr::rowwise() %>%
      dplyr::mutate(visit_flag = stringr::str_split(visit_flag, ",") %>%
                      unlist() %>%
                      stringr::str_trim() %>%
                      max())
  }, error = function(e){
    logger::log_error('Error flagging visit, returning empty tibble')
    return(tibble::tibble())
  })
}
