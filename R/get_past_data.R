#' @title get_past_data
#' @name get_past_data
#' @description Retrieve state vectors for a specific plane if the desired start time is before the current time.
#'
#' @param username Your 'OpenSky Network' username.
#' @param password Your 'OpenSky Network' password.
#' @param start_seconds_ago Amount of time (in seconds) before current time when user wants to start
#' collecting state vectors.
#' @param icao24 Unique ICAO 24-bit address of the transponder in hex string
#' representation. All letters need to be lower case.
#'
#' @return An sf object of state vectors for every 5-second snapshot, from the start time to current time
#'
#'
#' @examples
#' \dontrun{get_past_data(username = "your_username", password = "your_password",
#'  start_seconds_ago = 600, icao24 = "3c4b26")}
#'
#' @import httr
#' @import sf
#' @import dplyr
#' @import jsonlite
#' @export

get_past_data <- function(username, password, start_seconds_ago, icao24) {
  #gets current unix time
  current_time = floor(as.numeric(as.POSIXct(Sys.time())))
  test_time = current_time - start_seconds_ago

  url1 = "https://"
  url2 = ":"
  url3 = "@opensky-network.org/api/states/all?time="
  url4 = "&icao24="

  #creates complete url for API query
  url = paste(url1, username, url2, password, url3, current_time, url4, icao24, sep = "")
  state_vectors_df <- as.data.frame(fromJSON(url))

  while (test_time < current_time) {
    url = paste(url1, username, url2, password, url3, test_time, url4, icao24, sep = "")
    state_vectors_df <- rbind(state_vectors_df, as.data.frame(fromJSON(url)))
    test_time = test_time + 5
  }

  state_vectors_df <- rename(state_vectors_df, c("states.1" = "icao24", "states.2" = "callsign",
                                                 "states.3" = "origin_country", "states.4" = "time_position",
                                                 "states.5" = "last_contact", "states.6" = "longitude",
                                                 "states.7" = "latitude", "states.8" = "baro_altitude",
                                                 "states.9" = "on_ground", "states.10" = "velocity",
                                                 "states.11" = "true_track", "states.12" = "vertical_rate",
                                                 "states.13" = "sensors", "states.14" = "geo_altitude",
                                                 "states.15" = "squawk", "states.16" = "spi", "states.17" = "position_source"))

  #changes column data types
  state_vectors_df$time = NULL
  state_vectors_df$icao24 = as.character(state_vectors_df$icao24)
  state_vectors_df$callsign = as.character(state_vectors_df$callsign)
  state_vectors_df$origin_country = as.character(state_vectors_df$origin_country)
  state_vectors_df$time_position = as.integer(as.character(state_vectors_df$time_position))
  state_vectors_df$last_contact = as.integer(as.character(state_vectors_df$last_contact))
  state_vectors_df$baro_altitude = as.numeric(as.character(state_vectors_df$baro_altitude))
  state_vectors_df$on_ground = as.logical(as.character(state_vectors_df$on_ground))
  state_vectors_df$velocity = as.numeric(as.character(state_vectors_df$velocity))
  state_vectors_df$true_track = as.numeric(as.character(state_vectors_df$true_track))
  state_vectors_df$vertical_rate = as.integer(as.character(state_vectors_df$vertical_rate))
  state_vectors_df$sensors = as.null(as.character(state_vectors_df$sensors))
  state_vectors_df$geo_altitude = as.numeric(as.character(state_vectors_df$geo_altitude))
  state_vectors_df$squawk = as.character(state_vectors_df$squawk)
  state_vectors_df$spi = as.logical(as.character(state_vectors_df$spi))
  state_vectors_df$position_source = as.list(as.character(state_vectors_df$position_source))
  state_vectors_df$longitude = as.numeric(as.character(state_vectors_df$longitude))
  state_vectors_df$latitude = as.numeric(as.character(state_vectors_df$latitude))

  proj = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
  #creates sf from dataframe
  state_vectors_sf <- st_as_sf(state_vectors_df, coords = c("longitude", "latitude"), crs = proj)

  return(state_vectors_sf)
}
