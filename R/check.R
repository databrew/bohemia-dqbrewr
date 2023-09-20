#' Utility check function for doing checks
#' @export
#' @description This is an all-purpose checker to make checks based on any available check functionality we have on any datasets
#' @param input any file needed for the function you are doing checks on
#' @param func any function needed to run the function on the input file
#' @return check_object results
check <- function(input, func){
  p <- purrr::partial(func)
  p(input)
}
