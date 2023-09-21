#' Promote staging file to prod
#' @description Function to promote staging file to prod
#' @export
#' @import logger
#' @import dplyr
#' @import purrr
#' @import cloudbrewr
#' @import tidyr
#' @importFrom magrittr %>%
#' @importFrom data.table fwrite
#' @param check_results_obj this is a `check_result_object` coming from `check_` operation
#' @param store_historical parameter whether to store data as a historical file with partition
promote <- function(check_results_obj, store_historical = TRUE) {
  logger::log_info('Attempt to promote data to prod')
  run_date <- as.character(lubridate::date(lubridate::now()))

  # check if error df is 0, if not dont let user promote data to prod
  logger::log_info('Checking any available errors')
  if(nrow(check_results_obj$err_df) > 0){
    logger::log_error('Make sure that you do not have any errors, before promoting staging file to prod')
    stop()
  }

  # save file as current
  store_to_s3 <- purrr::map(check_results_obj$output_map, function(mp){
    tryCatch({
      fwrite(mp$data, mp$output_filename)
      aws_s3_store(
        filename = mp$output_filename,
        bucket = mp$bucket,
        key = mp$curr_s3_key)

      if(store_historical){
        aws_s3_store(
          filename = mp$output_filename,
          bucket = mp$bucket,
          key = glue::glue(mp$hist_s3_key, run_date = run_date))
      }
    }, error = function(e){
      logger::log_error('Failed storing staging files to prod')
      logger::log_error(e$message)
    })
  })
}
