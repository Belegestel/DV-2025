library(shiny)
library(shinydashboard)
library(plotly)
library(leaflet)
library(markdown)

dashboardPage(
  skin='black',
  dashboardHeader(
    title = "PUT Flight Tracker",
    tags$li(class='dropdown',
      tags$img(src='logo.jpg', height='40px')
    )
  ),
  dashboardSidebar(
    sidebarMenu(
      #menuItem("Dashboard", tabName = "dashboard", icon = icon("plane")),
      actionButton("fetch_flights", "Fetch flights"),
      sliderInput("lat_slider", "Latitude", min=-90, max=90, value=52.403797, step=0.0001),
      sliderInput("lon_slider", "Longitude", min=-180, max=180, value=16.949791, step=0.0001),
      sliderInput("dis_slider", "Distance", min=30, max=250, value=250, step=1),
      menuItem("Flight map", tabName="flight_map_tab", icon=icon("map")),
      menuItem("Flight data", tabName="flight_data_tab", icon=icon("plane")),
      menuItem("Airplane list", tabName="airplane_list", icon=icon("list")),
      menuItem("Help", tabName="help_tab", icon=icon("question"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML('
           /* Inactive track */
        .irs-line {
          background-color: #444 !important;
          border-color: #444 !important;
        }
    
        /* Active (selected range) track */
        .irs-bar {
          background-color: #111111 !important;
          border-color: #111111 !important;
        }
    
        /* Slider handle */
        .irs-handle {
          background-color: #111111 !important;
          border-color: #010101 !important;
        }
    
        /* Value labels above the handle */
        .irs-single,
        .irs-from,
        .irs-to {
          background-color: #111111 !important;
          color: #fff !important;
          border-color: #010101 !important;
        }
    
        /* Min and Max labels */
        .irs-min,
        .irs-max {
          color: #ccc !important;
        }
        '
      ))
    ),
    tabItems(
      tabItem(
        tabName="flight_map_tab",
        fluidRow(
          valueBoxOutput("total_airplane_count_box", width=12)
        ),
        fluidRow(
          width=12,
          column(width = 6,
            leafletOutput("flight_map", height=400)
          ),
          column(width = 6,
            plotlyOutput("flight_data_plot")
          )
        ),
        fluidRow(
          
        )
      ),
      tabItem(
        tabName='flight_data_tab',
        fluidRow(
          column(width=6,
            plotlyOutput("airlines_plot"),
            sliderInput("top_n_airlines", "Number of airlines to show", min=1, max=20, value=10)
          ),
          column(width=6,
            plotlyOutput("airplane_models_plot"),
            sliderInput("top_n_models", "Number of models", min=1, max=20, value=10)
          )
        )
      ),
      tabItem(
        tabName="airplane_list",
        tableOutput("flight_data_table")
      ),
      tabItem(
        tabName='help_tab',
        includeMarkdown("help.md")
      )
    )
  )
)