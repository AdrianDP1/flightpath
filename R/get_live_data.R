#' @title get_live_data
#' @name get_live_data
#' @description Retrieve all flight vectors every 5 seconds
#'  starting now up to a specified time into the future.
#' @param username Your 'OpenSky Network' username.
#' @param password Your 'OpenSky Network' password.
#' @param duration Amount of time (in seconds) for which to collect live data.
#' @param icao24 Optional. Unique icao24 identifier for aircraft
#' @param ... Optional placeholder for future parameters.
#'
#' @return If icao24 is missing, A non-spatial dataframe of all state vectors retrieved during the collection period.
#'   if icao24 specified, A geocoded sf is returned instead.
#'
#' @examples
#' \dontrun{collect_live_data(username = "your_username", password = "your_password",
#'  duration = 30)}
#'
#' @import openskyr
#' @import sf
#' @import tidyverse
#' @import httr
#' @import tidyr
#' @importFrom utils head
#' @export get_live_data

get_live_data <- function(username, password, duration, icao24 = NULL, ...) {
  #gets current unix time
  current_time = floor(as.numeric(as.POSIXct(Sys.time())))
  start_time = current_time

  #openskyr package query
  state_vectors_df = get_state_vectors(username = username, password = password, ...)
  icao24_arg = icao24

  if(!is.null(icao24_arg)){
    #filters dataframe for data regarding specific plane
    state_vectors_df = state_vectors_df %>%
      filter(icao24 == icao24_arg)
  }

  #waits 5 seconds
  Sys.sleep(5)

  while (current_time < start_time + duration) {
    next_df = get_state_vectors(username = username, password = password, ...)
    if(!is.null(icao24_arg)){
      next_df = next_df %>%
        filter(icao24 == icao24_arg)
    }
    state_vectors_df = rbind(state_vectors_df, next_df)
    Sys.sleep(5)
    current_time = as.numeric(as.POSIXct(Sys.time()))
    progress_str = paste("Live data: ",
                         pmin(((current_time - start_time)/(duration))*100,100),
                         "% complete. ",nrow(state_vectors_df)," vectors collected.")
    print(progress_str)
  }

  state_vectors_df = as.data.frame(state_vectors_df)

  #get state vectors function output uses columns which are lists
  #for loop produces a tibble which unlists the columns and removes NULL values
  for(name in head(names(state_vectors_df),-1)){
    if(!is.null(state_vectors_df[name][[1]][[1]])){
      state_vectors_df = unnest_longer(state_vectors_df,name)
    }
    else{
      state_vectors_df[name] = as.null(state_vectors_df[name])
    }
  }

  #back to normal data frame
  state_vectors_df = as.data.frame(state_vectors_df)
  if(!is.null(icao24_arg)){
    proj = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
    state_vectors_sf <- st_as_sf(state_vectors_df, coords = c("longitude", "latitude"), crs = proj)

    return(state_vectors_sf)
  }

  return(state_vectors_df)
}
