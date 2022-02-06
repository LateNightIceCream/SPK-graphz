# this version works with the regular .csv files exported from the web interface
# TODO: feature: input multiple csv files and overlay them
# TODO: feature: input multiple keywords and overlay them
library(ggplot2)
library(patchwork)
library(argparser)

parser <- arg_parser('A program to turn Sparkasse .csv files into nice graphs')
parser <- add_argument(parser, "input", help="input file")
parser <- add_argument(parser, '--keywords', default = 'all', help='keyword(s) to filter for. Case sensitive. Use \'|\' to OR multiple keywords. Examples: \'LIDL\' or \'LIDL|ALDI\'')
parser <- add_argument(parser, "--output", help="output (pdf) file")
parser <- add_argument(parser, "--type", default='x', help="show positive (+), negative (-) or both (~) amounts")

args <- parse_args(parser)

width   <- 10
height  <- 0.618 * width
dat     <- read.csv(args$input, sep=';')

keyword <- args$keywords
keyword
outname <- if (is.na(args$output) || args$output == '')  paste(args$keywords, '.pdf', sep='') else args$output
outname

format_data <- function (data, keyword, type = '-') {
    # only take rows where descr contains keyword
    # TODO: toLower()
    data <- if (keyword == 'all') data else dplyr::filter(data, grepl(keyword, descr))
    # pls no german decimal ','
    data$amount <- as.numeric(sub(',', '.', data$amount, fixed = TRUE))
    i = if (type == '+') { 1 }  else if (type == '-') { -1 } # else...

    if (type != 'x') {
      data <- dplyr::filter(data, i * amount > 0)
      data$amount <- abs(data$amount)
    }

    # get R date objects
    data$date <- as.Date(data$date, '%d.%m.%y')
    # just for convenience
    data$idu  <- as.numeric(row.names(data))
    # order by date
    data      <- data[order(data$date),]
    # get cumsum
    data$cum_amount <- cumsum(data$amount)
    data$weekdays <- weekdays(data$date)
    return(data)
}

# make format like legacy date,descr,amount
dat1 <- data.frame(date = dat$Buchungstag, descr=dat$Beguenstigter.Zahlungspflichtiger, amount = dat$Betrag)
dat1 <- format_data(dat1, keyword, type = args$type)

start_date <- dat1$date[1]
end_date   <- tail(dat1$date, n=1)

avg_amount <- mean(dat1$amount)

col1    <- 'gray'
col2    <- '#fa5252'
col3    <- '#339af0'
textcol <- '#212529'

right_axis_factor <- max(dat1$cum_amount) / max(dat1$amount)

geom_amount_timeplot <- function (data = dat1, color = col2, color2 = col3) {
  avg_amount <- mean(data$amount)
  #y <- data$cum_amount
  #data <- dplyr::mutate(data, line_color = y > 0 | dplyr::lead(y, default = dplyr::first(y)) < 0)
  list(
    geom_line(data = data, color='gray'),
    #geom_point(data = data, color=color),
    geom_point(data = data, aes(color = amount > 0)),
    #geom_point(data = data, aes(x = date, y=amount, colour = amount)),
    #scale_colour_gradient(low = color2, high = color),
    geom_line(data = data, aes(x=date, y=cum_amount/right_axis_factor), color="orange" ),
    geom_hline(yintercept=avg_amount, linetype='dashed', color=color),
    #geom_text(label=data$amount),
    # just for testing, date[4] is not very secure ;D
    annotate('text', x = data$date[4], y = avg_amount, color = textcol, label=sprintf('%.2f', avg_amount))

    )
}

# time plot
p <- ggplot(data = dat1, aes(x=date, y=amount)) +
  theme_minimal() +
  ggtitle(
    label = paste(keyword, 'expenses'),
    subtitle = paste('from', start_date, 'to', end_date)
  ) +
  theme(plot.title=element_text(color='black'),
        plot.subtitle=element_text(color='gray'),
        legend.position="none") +
  scale_y_continuous(
    # Features of the first axis
    name = 'amount / EUR',
    # Add a second axis and specify its features
    sec.axis = sec_axis( trans=~.*right_axis_factor, name='cumulative amount / EUR'),
    breaks = scales::pretty_breaks(n = 6)
  ) +
  geom_amount_timeplot()
  #geom_amount_timeplot(data=dat2, color='red')

# weekday plot
w <- ggplot(data = aggregate(dat1$amount, list(dat1$weekdays), mean), aes(Group.1, x), ) +
  theme_minimal() +
  geom_col()

# histogram
h <- ggplot(data = dat1, aes(x=amount)) +
  theme_minimal() +
  geom_histogram()

pdf(outname, width, height)
p
