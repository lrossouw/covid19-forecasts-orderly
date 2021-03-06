projection_plot <- function(obs, pred) {

    ## Number of projections
  nprojs <- length(unique(pred$proj))

  ## Latest projections get a different color
  ## if (nprojs == 1) {
  ##   palette <- c("#b3669e")
  ## } else {
  ##   palette <- c(
  ##     rep("#98984d", nprojs - 1),
  ##     "#b3669e"
  ##   )
  ## }
  ## names(palette) <- unique(pred$proj)

  ## Plot only the latest projections.
  palette <- c("#E69F00", "#56B4E9", "#009E73", "#D55E00", "#CC79A7", "#999999")
  names(palette) <- c(
    "Model 4", "Model 2", "Model 1", "Model 3", "Ensemble", "Weighted Ensemble"
  )
  pred <- pred[pred$week_ending == max(as.Date(pred$week_ending)), ]

  ## date_min <- max(
  ##   as.Date(pred$week_ending) - 28, as.Date("2020-03-01")
  ## )
  date_min <- as.Date("2020-03-01")
  date_max <- max(pred$date) + 2
  dates_to_mark <- seq(
    from = date_min,
    to = date_max,
    by = "1 day"
  )
  dates_to_mark <- dates_to_mark[weekdays(dates_to_mark) == "Monday"]
  ## Get dates of adding vlines.
  window_eps <- dplyr::group_by(pred, proj) %>%
    dplyr::summarise(date = min(date)) %>%
    dplyr::ungroup()

  window_eps$xintercepts <- as.numeric(
    window_eps$date - 1
  ) + 0.5
  ## To get nice labels
  ## https://joshuacook.netlify.com/post/integer-values-ggplot-axis/
  integer_breaks <- function(n = 5, ...) {
    fxn <- function(x) {
      breaks <- floor(pretty(x, n, ...))
      names(breaks) <- attr(breaks, "labels")
      breaks
    }
    return(fxn)
  }

  p <- ggplot() +
    geom_point(data = obs, aes(dates, deaths)) +
    geom_line(
      data = pred,
      aes(date, `50%`, col = proj, group = proj)
    ) +
    geom_ribbon(
      data = pred,
      aes(x = date,
          ymin = `2.5%`,
          ymax = `97.5%`,
          fill = proj,
          group = proj),
      alpha = 0.4) +
    scale_color_manual(
      values = palette,
      aesthetics = c("color", "fill"),
    ) +
    theme_project() +
    theme(legend.position = "top", legend.title = element_blank()) +
    scale_x_date(breaks = dates_to_mark, limits = c(date_min, date_max)) +
    scale_y_continuous(breaks = integer_breaks()) +
    geom_vline(
      xintercept = c(
        window_eps$xintercepts
      ),
      linetype = "dashed"
    ) + xlab("") +
    ylab("Deaths") +
    theme(
      axis.text.x = element_text(angle = -90)
    )

  p
}


rt_lineplot <- function(rt, nice_names) {

  palette <- c("#E69F00", "#56B4E9", "#009E73", "#D55E00", "#CC79A7")
  names(palette) <- c("Model 4", "Model 2", "Model 1", "Model 3", "Ensemble")



    rt$country <- reorder(rt$country, -rt$`50%`)
    if (length(unique(rt$model)) == 1) width <- 0.1
    else width <- 0.7

    p <- ggplot() +
        geom_errorbar(
            data = rt,
            aes(x = country, ymin = `2.5%`, ymax = `97.5%`, col = proj),
            position = position_dodge(width = width),
            size = 1.1
        ) +
        geom_point(
            data = rt,
            aes(x = country, y = `50%`, col = proj),
            position = position_dodge(width = width),
            size = 4
        ) +
      theme_project() +
        xlab("") +
        ylab("Effective Reproduction Number") +
        scale_x_discrete(labels = nice_names) +
        geom_hline(
            yintercept = 1,
            linetype = "dashed"
        ) + theme_project() +
          scale_color_manual(
            values = palette
          ) + coord_flip()

    p
}


rt_boxplot <- function(rt, nice_names) {

  #nice_names <- snakecase::to_title_case(rt$country)
  #names(nice_names) <- rt$country
  ##rt$country <- reorder(rt$country, -rt$`50%`)
  palette <- c("#E69F00", "#56B4E9", "#009E73", "#D55E00", "#CC79A7")
  names(palette) <- c("Model 4", "Model 2", "Model 1", "Model 3", "Ensemble")

  rt$country <- reorder(rt$country, -rt$`50%`)
  p <- ggplot(rt) +
  geom_boxplot(
    aes(
      y = country,
      xmin = `2.5%`,
      xmax = `97.5%`,
      xmiddle = `50%`,
      xlower = `25%`,
      xupper = `75%`,
      fill = proj
    ),
    alpha = 0.3,
    stat = "identity"
  ) +
    xlab("Effective Reproduction Number") +
    ylab("") +
    scale_y_discrete(labels = nice_names) +
    geom_vline(
      xintercept = 1,
      linetype = "dashed"
    ) + theme_project() +
    scale_fill_manual(values = palette) +
    theme(
      legend.position = "top",
      legend.title = element_blank()
    )

  p
}

add_continents <- function(df, mapping) {

  df$iso3c <- countrycode::countrycode(
    snakecase::to_title_case(df$country),
      "country.name",
      "iso3c"
   )

  df <- dplyr::left_join(
    df,
    mapping,
    by = c("iso3c" = "three_letter_country_code")
  )
  df
}
