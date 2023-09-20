# DataBrew Data Quality Checker 
Author: atediarjo@gmail.com, joe.brew@gmail.com

R package for testing metadata and interact with AWS

## Prerequisites

To fully run this package you will require access to DataBrew AWS Accounts via SSO (please contact atediarjo@gmail.com for access). To configure AWS environment in your RStudio, run this command:

```r
tryCatch({
  logger::log_info('Attempt AWS login')
  # login to AWS - this will be bypassed if executed in CI/CD environment
  cloudbrewr::aws_login(
    role_name = 'cloudbrewr-aws-role',
    profile_name =  'cloudbrewr-aws-role')

}, error = function(e){
  logger::log_error('AWS Login Failed')
  stop(e$message)
})
```

## Installation

Installation can be done through Github installation:

```r
devtools::install_github('databrew/dataqualitybrewr')
```

## Workflow

![](./man/figures/dqwf.png)

## How-To

1. Check zip file submission
```r
check_results <- check(input = 'PATH/TO/HECON/ZIPFILE', func = check_healthecon)
```

2. After running checks, you will get an output of a `check_result` object mapping. The object mapping will contain the list of all available errors.

To check errors from unit test:
```r
check_results$err_df
```

To check how your files will be stored in AWS (recursively):
```r
check_results$output_map
```

3. Once all test have passed and resolved, parse `check_result` object mapping to promote function

```r
promote(check_results, store_historical = TRUE)
```

4. After promoting the `check_result` object, data will be stored in AWS for tracking / validation
