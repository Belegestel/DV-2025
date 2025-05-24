library(shiny)
library(httr)
library(jsonlite)
library(shinydashboard)
library(plotly)
library(leaflet)

function(input, output, session) {
  data_response = eventReactive(input$fetch_flights, {
    lat = input$lat_slider
    lon = input$lon_slider
    dis = input$dis_slider
    url = paste("https://api.airplanes.live/v2/point/", lat, "/", lon, "/", dis, sep='')
    #print('Starting')
    resp = GET(url)
    #print('GET finished')
    
    if(status_code(resp) == 200) {
      json_data = content(resp, as="text", encoding="UTF-8")
      parsed_data = fromJSON(json_data)$ac
      #print(parsed_data)
      required_cols = c("mag_heading", "gs", "squawk", "ownOp", "lat", "lon", "flight", "alt_baro", "t")
      if(length(parsed_data) == 0) {
        df = data.frame(matrix(ncol=9, nrow=0))
        colnames(df) = required_cols
        #print('Parse done')
        return(df)
      }
      df = as.data.frame(parsed_data)
      for(c in required_cols) {
        if(c %in% colnames(df)) {
          #print(paste(c, "in data"))
        }
        else {
          #print(paste(c, "in data"))
          df[c] = NA
        }
      }
      #print(colnames(df))
      df = df[required_cols]
      df$alt_baro = as.numeric(as.character(df$alt_baro))
      #print('Parse done')
      return(df)
    }
    else {
      print(paste("Request failed, code", status_code(resp)))
      return(paste("Request failed, code", status_code(resp)))
    }
  })
  
  output$total_airplane_count_box = renderValueBox({
    if(is.null(data_response())) {
      return(shinydashboard::valueBox(
        value=0,
        subtitle="No data fetched yet!",
        color="green",
        icon=icon('plane')
      ))
    }
    else {
      return(shinydashboard::valueBox(
        value=nrow(data_response()),
        subtitle="Planes within 250NM",
        icon=icon('plane'),
        color='black'
      ))
    }
  })
  
  
  output$flight_data_plot = renderPlotly({
    df = data_response()
    p = plot_ly(df, x = ~gs, y = ~alt_baro, 
            type = 'scatter', mode = 'markers', 
            marker = list(color = 'rgba(10, 10, 10, 0.7)', size = 10),
            key = ~flight,
            text = ~paste("Flight: ", flight, 
                          "<br>Type: ", t,
                          "<br>Altitude: ", alt_baro, " ft",
                          "<br>Ground Speed: ", gs, " knots",
                          "<br>Heading: ", mag_heading, " degrees",
                          "<br>Squawk: ", squawk,
                          "<br>Operator: ", ownOp),
            hoverinfo = 'text'
            ) %>%
      layout(title = "Flight Data: Altitude vs. speed",
             xaxis = list(title = "Speed (kts)"),
             yaxis = list(title = "Altitude (ft)"),
             dragmode='select') 
    p %>% event_register('plotly_selected')
  })
  
  selected_planes = reactive({
    e = event_data('plotly_selected')
    df = data_response()
    if(is.null(e) || is.null(e$key) || length(e$key) == 0) {
      return(df)
    }
    df[df$flight %in% e$key, ]
  })
  
  output$flight_map = renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = 16.949791, lat = 52.403797, zoom = 6)
  })
  observeEvent(input$fetch_flights, {
    data = selected_planes()
    req(data, nrow(data) > 0, !any(is.na(data$lat)), !any(is.na(data$lon)))
    leafletProxy("flight_map", data=data) %>%
        clearMarkers() %>%
        addTiles() %>%
        addAwesomeMarkers(
          lng = ~lon, lat = ~lat,
          icon = awesomeIcons(
            icon='plane',
            iconColor='black',
            library='fa',
            markerColor='white'
          ),
          popup = ~paste(
            "Flight: ", flight, "<br>",
            "Type: ", t, "<br>",
            "Heading: ", mag_heading, "<br>",
            "Altitude: ", alt_baro, " ft", "<br>",
            "Ground Speed: ", gs, " knots", "<br>",
            "Squawk: ", squawk, "<br>",
            "Operator: ", ownOp
        ))
    }
  )
  
  observe({
    data = selected_planes()
    req(data, nrow(data) > 0, !any(is.na(data$lat)), !any(is.na(data$lon)))
    leafletProxy("flight_map", data=data) %>%
        clearMarkers() %>%
        addTiles() %>%
        addAwesomeMarkers(
          lng = ~lon, lat = ~lat,
          icon = awesomeIcons(
            icon='plane',
            iconColor='black',
            library='fa',
            markerColor='white'
          ),
          popup = ~paste(
            "Flight: ", flight, "<br>",
            "Type: ", t, "<br>",
            "Heading: ", mag_heading, "<br>",
            "Altitude: ", alt_baro, " ft", "<br>",
            "Ground Speed: ", gs, " knots", "<br>",
            "Squawk: ", squawk, "<br>",
            "Operator: ", ownOp
        ))
  })
  
  output$flight_data_table = renderTable({
    df = selected_planes()
    colnames(df) = c("Heading", "Ground speed", "Squawk", 'Operator',
                     "Latitude", "Longitude", "Flight", "Altitude", "Type")
    df
  }, striped=T, hover=T)
  
  output$airlines_plot = renderPlotly({
    df = selected_planes()
    counts = as.data.frame(table(df$ownOp))
    colnames(counts) = c("Airline", "Count")
    counts = head(counts[order(-counts$Count), ], input$top_n_airlines)
    counts$Airline = droplevels(counts$Airline)
    counts$Airline = factor(counts$Airline, levels=counts$Airline)
    plot_ly(counts, y=~Airline, x=~Count, type='bar', orientation='h',
            marker=list(color='rgba(10, 10, 10, 0.7')) %>%
      layout(title="Most common airlines",
             xaxis=list(title="Airline"),
             yaxis=list(title="Number of flights"),
             showlegend=F)
  })
  
  output$airplane_models_plot = renderPlotly({
    df = selected_planes()
    counts = as.data.frame(table(df$t))
    colnames(counts) = c("Type", "Count")
    counts = head(counts[order(-counts$Count), ], input$top_n_models)
    counts$Type = droplevels(counts$Type)
    counts$Type = factor(counts$Type, levels=counts$Type)
    plot_ly(counts, y=~Type, x=~Count, type='bar', orientation='h',
            marker=list(color='rgba(10, 10, 10, 0.7')) %>%
      layout(title="Most common aircraft types",
             xaxis=list(title="Aircraft type"),
             yaxis=list(title="Number of flights"),
             showlegend=F)
  })
}
