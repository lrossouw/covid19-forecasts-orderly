### This task produces the following visualtions:
### comparison of unweighted and weighted ensembles for each country
### all forecasts from unweighted ensemble
### all forecasts from weighted ensemble with weights coming from
### last week
### all forecasts from weighted ensemble with weights coming from
###all previous weeks

main_text_countries <- c(
  "Brazil", "India", "Italy", "Mexico", "United_States_of_America"
)

unweighted_qntls <- readRDS("unweighted_qntls.rds") %>%
  dplyr::filter(si == use_si)

wtd_prev_week <- readRDS("wtd_prev_week_qntls.rds") %>%
  dplyr::filter(si == use_si)

wtd_all_prev_weeks <- readRDS("wtd_all_prev_weeks_qntls.rds") %>%
    dplyr::filter(si == use_si)

unweighted_qntls$date <- as.Date(unweighted_qntls$date)
wtd_prev_week$date <- as.Date(wtd_prev_week$date)
wtd_all_prev_weeks$date <- as.Date(wtd_all_prev_weeks$date)


## Performance Metrics



## deaths_tall <- deaths_tall[deaths_tall$country %in% unweighted_qntls$country, ]
## levels <- unique(interaction(both$proj, both$model))
## unwtd <- grep(pattern = "Unweighted", x = levels, value = TRUE)
## wtd <- grep(pattern = "Unweighted", x = levels, value = TRUE, invert TRUE)
## palette <- c(rep("#b067a3", nlevels(levels) / 2),
##              rep("#9c954d", nlevels(levels) / 2))
## names(palette) <- c(unwtd, wtd)

countries <- unique(unweighted_qntls$country)
si_countries <- countries[! countries %in% main_text_countries]
names(si_countries) <- si_countries
## Put all main text countries in one list,
## all others by themselves.
countries <- list(main = main_text_countries)
countries <- append(x = countries, values = unlist(si_countries))

purrr::iwalk(
  countries,
  function(country, name) {
    obs <-  unweighted_qntls[unweighted_qntls$country %in% country, c("date", "country" ,"deaths")]
    pred <- unweighted_qntls[unweighted_qntls$country %in% country, ]
    pred <- cap_predictions(pred)

    p <- all_forecasts(obs, pred)
    outfile <- glue::glue("{name}_forecasts.tiff")
    ggsave(outfile, p)
  }
)

purrr::iwalk(
  countries,
  function(country, name) {
    obs <-  unweighted_qntls[unweighted_qntls$country %in% country, c("date", "country" ,"deaths")]
    pred <- wtd_prev_week[wtd_prev_week$country %in% country, ]
    pred <- cap_predictions(pred)
    p <- all_forecasts(obs, pred)
    outfile <- glue::glue("{name}_forecasts_wtd_prev_week.tiff")
    ggsave(outfile, p)
  }
)

purrr::iwalk(
  countries,
  function(country, name) {
    obs <-  unweighted_qntls[unweighted_qntls$country %in% country, c("date", "country" ,"deaths")]
    pred <- wtd_all_prev_weeks[wtd_all_prev_weeks$country %in% country, ]
    pred <- cap_predictions(pred)
    p <- all_forecasts(obs, pred)
    outfile <- glue::glue("{name}_forecasts_wtd_all_prev_weeks.tiff")
    ggsave(outfile, p)
  }
)



countries <- unique(wtd_prev_week$country)

purrr::walk(
  countries,
  function(country) {
    obs <-  unweighted_qntls[unweighted_qntls$country %in% country, c("date", "country" ,"deaths")]
    pred <- unweighted_qntls[unweighted_qntls$country %in% country, ]
    pred <- cap_predictions(pred)

    p <- ggplot() +
      geom_point(
        data = obs,
        aes(date, deaths),
        col = "black"
      ) +
      geom_line(
        data = pred,
        aes(x = date, `50%`, group = proj, col = "#0072B2"),
        size = 1
      ) +
      geom_ribbon(
        data = pred,
        aes(
          x = date,
          ymin = `2.5%`,
          ymax = `97.5%`,
          group = proj,
          fill = "#0072B2"
        ),
        alpha = 0.3
      ) +
      theme_classic() +
      theme(legend.position = "none", legend.title = element_blank()) +
      xlab("") +
      ylab("") +
      scale_x_date(limits = c(as.Date("2020-03-01"), NA)) +
      facet_wrap(~country)

    ### Unweighted and weighted comparison
    wtd1 <- wtd_prev_week[wtd_prev_week$country %in% country, ] %>%
      cap_predictions()

    wtd2 <- wtd_all_prev_weeks[wtd_all_prev_weeks$country %in% country, ] %>%
      cap_predictions()

    message(country)
    p1 <- p +
      geom_ribbon(
        data = wtd1,
        aes(
          x = date,
          ymin = `2.5%`,
          ymax = `97.5%`,
          group = proj,
          fill = "#D55E00"
        ),
        alpha = 0.3
      ) +
      ## geom_ribbon(
      ##   data = wtd1,
      ##   aes(x = date, ymin = `25%`, ymax = `75%`, group = proj),
      ##   fill = "#D55E00",
      ##   alpha = 0.5
      ## ) +
      geom_line(
        data = wtd1,
        aes(x = date, `50%`, group = proj, col = "#D55E00"),
        size = 1
      ) +

      geom_ribbon(
        data = wtd2,
        aes(
          x = date,
          ymin = `2.5%`,
          ymax = `97.5%`,
          group = proj,
          fill = "#CC79A7"
        ),
        alpha = 0.3
      ) +
      ## geom_ribbon(
      ##   data = wtd2,
      ##   aes(x = date, ymin = `25%`, ymax = `75%`, group = proj),
      ##   fill = "#CC79A7",
      ##   alpha = 0.5
      ## ) +
      geom_line(
        data = wtd2,
        aes(x = date, `50%`, group = proj, col = "#CC79A7"),
        size = 1
      ) +
      scale_fill_identity(
        breaks = c("#0072B2", "#D55E00", "#CC79A7"),
        labels = c("Unweighted", "Previous Week", "All previous weeks"),
        guide = "legend"
      ) +
      scale_color_identity(
        breaks = c("#0072B2", "#D55E00", "#CC79A7"),
        labels = c("Unweighted", "Previous Week", "All previous weeks"),
        guide = "legend"
      ) +
      theme(legend.position = "top", legend.title = element_blank())

    ggsave(glue::glue("{country}_forecasts_comparison.tiff"), p1)
  }
)



######### Performance metrics
observed <- unweighted_qntls[, c("date", "country", "deaths")]

labels <- c(
  "rel_mae" = "Relative mean error",
  "rel_mse" = "Relative mean squared error",
  "rel_sharpness" = "Relative sharpness",
  "bias" = "Bias",
  "prop_in_50" = "Proportion in 50% CrI",
  "prop_in_975" = "Proportion in 97.5% CrI",
  "empirical_p" = "Probability(obs|predictions)"
)


wtd_all_prev_weeks_error <- readr::read_csv(
  "wtd_all_prev_weeks_error.csv"
)
wtd_all_prev_weeks_error$strategy <- "Weighted (all previous weeks)"

wtd_all_prev_weeks_error <- tidyr::separate(
  wtd_all_prev_weeks_error,
  col = "model",
  into = c(NA, NA, NA, NA, "forecast_date"),
  sep = "_"
)

p1 <- metrics_over_time(
  wtd_all_prev_weeks_error,
  use_si,
  main_text_countries,
  "rel_mae",
  labels
)

p1 <- p1 +
  geom_hline(yintercept = 1, linetype = "dashed") +
  scale_y_log10(
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = scales::trans_format("log10", scales::math_format(10^.x))
  ) +
  annotation_logticks(sides = "l")

p2 <- metrics_over_time(
  wtd_all_prev_weeks_error,
  use_si,
  main_text_countries,
  "rel_sharpness",
  labels
)

p <- cowplot::plot_grid(
  p1, p2, labels = c('A', 'B'), label_size = 12, align = "l", ncol = 1
)

cowplot::save_plot("wtd_all_prev_weeks_metrics.tiff", p, base_height = 5)

wtd_prev_week_error <- readr::read_csv(
  "wtd_prev_week_error.csv"
  )

wtd_prev_week_error$strategy <- "Weighted (previous week)"
wtd_prev_week_error <- tidyr::separate(
  wtd_prev_week_error,
  col = "model",
  into = c(NA, NA, NA, "forecast_date"),
  sep = "_"
)


p1 <- metrics_over_time(
  wtd_prev_week_error,
  use_si,
  main_text_countries,
  "rel_mae",
  labels
)

p1 <- p1 +
  geom_hline(yintercept = 1, linetype = "dashed") +
  scale_y_log10(
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = scales::trans_format("log10", scales::math_format(10^.x))
  ) +
  annotation_logticks(sides = "l")

p2 <- metrics_over_time(
  wtd_prev_week_error,
  use_si,
  main_text_countries,
  "rel_sharpness",
  labels
)

p <- cowplot::plot_grid(
  p1, p2, labels = c('A', 'B'), label_size = 12, align = "l", ncol = 1
)

cowplot::save_plot("wtd_prev_week_metrics.tiff", p, base_height = 5)


unwtd_pred_error <- readr::read_csv("unwtd_pred_error.csv")
unwtd_pred_error$rel_mae <- log(
  unwtd_pred_error$rel_mae, 10
)
unwtd_pred_error$strategy <- "Unweighted"
unwtd_pred_error <- tidyr::separate(
  unwtd_pred_error,
  col = "model",
  into = c(NA, "forecast_date"),
  sep = "_"
)

p1 <- metrics_over_time(
  unwtd_pred_error,
  use_si,
  main_text_countries,
  "rel_mae",
  labels
)

p1 <- p1 +
  geom_hline(yintercept = 1, linetype = "dashed") +
  scale_y_log10(
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = scales::trans_format("log10", scales::math_format(10^.x))
  ) +
  annotation_logticks(sides = "l")

p2 <- metrics_over_time(
  unwtd_pred_error,
  use_si,
  main_text_countries,
  "rel_sharpness",
  labels
)

p <- cowplot::plot_grid(
  p1, p2, labels = c('A', 'B'), label_size = 12, align = "l", ncol = 1
)

cowplot::save_plot("unwtd_pred_metrics.tiff", p, base_height = 5)

## df <- rbind(
##   wtd_all_prev_weeks_error, wtd_prev_week_error, unwtd_pred_error
## )
## df <- df[df$si == use_si, ]

## df <- dplyr::left_join(df, observed)
## df$incid_level <- dplyr::case_when(
##   df$deaths <= 20 ~ "Less than 20 deaths",
##   df$deaths > 20 ~ "More than 20 deaths",
## )

## dftall <- tidyr::gather(df, var, val, `rel_mae`:`poisson_p`)


## x <- dplyr::filter(
##   dftall,
##   var %in% c("rel_mae", "rel_sharpness") &
##   country %in% main_text_countries
##   )

## x$val[x$var == "rel_mae"] <- log(x$val[x$var == "rel_mae"], base = 10)


## ggplot(x, aes(forecast_date, val, fill = strategy)) +
##   geom_boxplot() +
##   facet_wrap( ~ var, scales = "free_y", ncol = 1)

