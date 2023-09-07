make_clean_data <- function(path) {
  # Load original pre-anonymized Qualtrics data
  data_raw <- read_csv(path, guess_max = 1500, show_col_types = FALSE)
  
  # Keep only eligible respondents
  data_eligible <- data_raw %>%
    filter(V10 == 1) %>%          # Keep respondents who completed the entire survey
    filter(Q1.1 == 1) %>%         # Keep respondents who gave consent
    filter(Q2.5 %in% c(1:5)) %>%  # Keep respondents who passed the screener
    filter(Q2.11 == 3)            # Keep respondents who passed the attention check
  
  # Get full data ready for cleaning and merging
  data_pre_clean <- data_eligible %>% 
    mutate(id = row_number()) %>% 
    rename(version = vers_CBCONJOINT) %>% 
    select(-contains("_TEXT")) %>% 
    select(id, version, Q1.1:Q5.18)
  
  # MEGA CLEANING PIPELINE
  data_clean <- data_pre_clean %>% 
    mutate(
      # *Q2.1*: How often do you follow national news? 
      # 
      # - Multiple times a day → At least once a day
      # - Every day → At least once a day
      # - Once a week → Once a week
      # - Hardly ever → Rarely (base case)
      # - Never → Rarely
      Q2.1 = factor(
        case_when(
          Q2.1 == 1 ~ "At least once a day",
          Q2.1 == 2 ~ "At least once a day",
          Q2.1 == 3 ~ "Once a week",
          Q2.1 == 4 ~ "Rarely",
          Q2.1 == 5 ~ "Rarely"
        ),
        levels = c("Rarely", "Once a week", "At least once a day"),
        labels = str_c(
          "Follow national news: ",
          c("Rarely", "Once a week", "At least once a day")
        )
      ),
      # *Q2.2*: How often do you follow international news? 
      # 
      # - Always
      # - Sometimes
      # - Never
      Q2.2 = fct_relevel(
        factor(
          Q2.2, 
          labels = str_c(
            "Follow international news: ", 
            c("Always", "Sometimes", "Never")
          ),
        ),
        str_c(
          "Follow international news: ", 
          c("Never", "Sometimes", "Always")
        )
      )
    ) %>% 
    mutate(
      # *Q2.3*: Which mediums do you use to follow news? (Select all that apply.)
      # 
      # - TV
      # - Print 
      # - Online (excluding social media) 
      # - Social media
      # - Radio
      # - Email newsletters
      # - News app
      across(contains("Q2.3"), ~coalesce(.x, 0))
    ) %>%
    mutate(
      Q2.3_1 = factor(Q2.3_1, labels = str_c("Medium to follow news: ", c("No TV", "TV"))),
      Q2.3_2 = factor(Q2.3_2, labels = str_c("Medium to follow news: ", c("No Print", "Print"))),
      Q2.3_3 = factor(Q2.3_3, labels = str_c(
        "Medium to follow news: ", 
        c("No Online (excluding social media)", "Online (excluding social media)")
      )),
      Q2.3_4 = factor(Q2.3_4, labels = str_c(
        "Medium to follow news: ", 
        c("No Social media", "Social media")
      )),
      Q2.3_5 = factor(Q2.3_5, labels = str_c("Medium to follow news: ", c("No Radio", "Radio"))),
      Q2.3_6 = factor(Q2.3_6, labels = str_c(
        "Medium to follow news: ", 
        c("No Email newsletters", "Email newsletters")
      )),
      Q2.3_7 = factor(Q2.3_7, labels = str_c(
        "Medium to follow news: ", 
        c("No News app", "News app")
      )),
      # *Q2.4*: How often would you say you follow what's going on in government and public affairs?
      # 
      # - Most of the time → Often
      # - Some of the time → Often
      # - Only now and then → Not often (base case)
      # - Hardly at all → Not often (base case)
      Q2.4 = factor(
        case_when(
          Q2.4 == 1 ~ "Often",
          Q2.4 == 2 ~ "Often",
          Q2.4 == 3 ~ "Not often",
          Q2.4 == 4 ~ "Not often"
        ),
        levels = c("Not often", "Often"),
        labels = str_c(
          "Follow government and public affairs: ",
          c("Not often", "Often")
        )
      ),
      # *Q2.5*: How often do you donate to charity (with either cash or in-kind)?
      # 
      # - Once a week → At least once a month
      # - Once a month → At least once a month
      # - Once every three months → More than once a month, less than once a year
      # - Once every six months → More than once a month, less than once a year
      # - Once a year → More than once a month, less than once a year (base case)
      Q2.5 = factor(
        case_when(
          Q2.5 == 1 ~ "At least once a month",
          Q2.5 == 2 ~ "At least once a month",
          Q2.5 == 3 ~ "More than once a month, less than once a year",
          Q2.5 == 4 ~ "More than once a month, less than once a year",
          Q2.5 == 5 ~ "More than once a month, less than once a year"
        ),
        levels = c("More than once a month, less than once a year", "At least once a month"),
        labels = str_c(
          "Donation frequency: ",
          c("More than once a month, less than once a year", "At least once a month")
        )
      ),
      # *Q2.6*: How much did you donate to charity last year?
      # 
      # - $1 to $49
      # - $50 to $99
      # - $100 to $499
      # - $500 to $999
      # - $1000 to $4,999
      # - $5000 to $9,999
      # - $10,000 or more
      Q2.6 = factor(
        Q2.6, 
        labels = str_c("Donated last year: ", c(
          "$1-$49", "$50-$99", "$100-$499", "$500-$999", 
          "$1000-$4,999", "$5000-$9,999", "$10,000+")),
        ordered = TRUE
      ),
      # *Q2.7*: On a scale of not at all important (1) to essential (7), how important is it for you to trust charities?
      # 
      # - 1 (Not at all important)
      # - 2
      # - 3
      # - 4
      # - 5
      # - 6
      # - 7 (Essential)
      Q2.7 = factor(
        Q2.7,
        labels = str_c("Importance of trusing charities: ", c(
          "Not at all important", "Very unimportant", "Somewhat unimportant", 
          "Neutral", "Somewhat important", "Very important", "Essential"
        )),
        ordered = TRUE
      ),
      # *Q2.8*: On a scale of no trust at all (1) to complete trust (7), how much do you trust charities?
      # 
      # - 1 (No trust at all)
      # - 2
      # - 3
      # - 4
      # - 5
      # - 6
      # - 7 (Complete trust)
      Q2.8 = factor(
        Q2.8,
        labels = str_c("Trust in charities: ", c(
          "No trust at all", "Very little trust", "Little trust", 
          "Neutral", "Some trust", "A lot of trust", "Complete trust"
        )),
        ordered = TRUE
      ),
      # *Q2.9*: Have you volunteered in the past 12 months?
      # 
      # - Yes
      # - No
      Q2.9 = fct_relevel(
        factor(Q2.9, labels = str_c("Volunteered in past 12 months: ", c("Yes", "No"))), 
        str_c("Volunteered in past 12 months: ", c("No", "Yes"))
      ),
      # *Q2.10*: How often do you volunteer?
      # 
      # - NA → Haven't volunteered in past 12 months (base case)
      # - Once a week → At least once a month
      # - Once a month → At least once a month
      # - Once every three months → More than once a month, less than once a year
      # - Once every six months → More than once a month, less than once a year
      # - Once a year → More than once a month, less than once a year
      # - Once every few years → Rarely
      Q2.10 = factor(
        case_when(
          is.na(Q2.10) == TRUE ~ "Haven't volunteered in past 12 months",
          Q2.10 == 1 ~ "At least once a month",
          Q2.10 == 2 ~ "At least once a month",
          Q2.10 == 3 ~ "More than once a month, less than once a year",
          Q2.10 == 4 ~ "More than once a month, less than once a year",
          Q2.10 == 5 ~ "More than once a month, less than once a year",
          Q2.10 == 6 ~ "Rarely"
        ),
        levels = c("Haven't volunteered in past 12 months", "Rarely", "More than once a month, less than once a year", "At least once a month"),
        labels = str_c(
          "Volunteer frequency: ",
          c("Haven't volunteered in past 12 months", "Rarely", "More than once a month, less than once a year", "At least once a month")
        )
      ),
      # *Q5.1*: Did you vote in the last election?
      # 
      # - Yes
      # - No
      Q5.1 = fct_relevel(
        factor(Q5.1, labels = str_c("Voted in last election: ", c("Yes", "No"))), 
        str_c("Voted in last election: ", c("No", "Yes"))
      ),
      # *Q5.2*: On a scale of extremely liberal (1) to extremely conservative (7), how would you describe your political views?
      # 
      # - 1 (Extremely liberal)
      # - 2
      # - 3
      # - 4
      # - 5
      # - 6
      # - 7 (Extremely conservative)
      Q5.2 = factor(
        Q5.2,
        labels = str_c("Liberal to Conservative: ", c(
          "Extremely liberal", "Somewhat liberal", "Slightly liberal", "Moderate",
          "Slightly conservative", "Somewhat conservative", "Extremely conservative"
        )),
        ordered = TRUE
      ),
      # *Q5.3*: Here is a list of different types of voluntary organizations. For each organization, 
      # indicate whether you are an active member, an inactive member, or not a member of that type of organization:
      # 
      # |                                         | Active member | Inactive member | Don't belong |
      # | --------------------------------------- | :-----------: | :-------------: | :----------: |
      # | Church or religious organization        |       •       |        •        |      •       |
      # | Sport or recreational organization      |       •       |        •        |      •       |
      # | Art, music, or educational organization |       •       |        •        |      •       |
      # | Labor union                             |       •       |        •        |      •       |
      # | Political party                         |       •       |        •        |      •       |
      # | Environmental organization              |       •       |        •        |      •       |
      # | Professional association                |       •       |        •        |      •       |
      # | Humanitarian or charitable organization |       •       |        •        |      •       |
      # | Consumer organization                   |       •       |        •        |      •       |
      # | Other organization                      |       •       |        •        |      •       |
      Q5.3_1 = fct_relevel(
        factor(Q5.3_1, labels = str_c(
          "Church or religious organization: ", 
          c("Active member", "Inactive member", "Don't belong"))
        ), 
        str_c(
          "Church or religious organization: ", 
          c("Don't belong", "Inactive member", "Active member")
        )
      ),
      Q5.3_2 = fct_relevel(
        factor(Q5.3_2, labels = str_c(
          "Sport or recreational organization: ",
          c("Active member", "Inactive member", "Don't belong"))
        ), 
        str_c(
          "Sport or recreational organization: ",
          c("Don't belong", "Inactive member", "Active member")
        )
      ),
      Q5.3_3 = fct_relevel(
        factor(Q5.3_3, labels = str_c(
          "Art, music, or educational organization: ",
          c("Active member", "Inactive member", "Don't belong"))
        ), 
        str_c(
          "Art, music, or educational organization: ",
          c("Don't belong", "Inactive member", "Active member")
        )
      ),
      Q5.3_4 = fct_relevel(
        factor(Q5.3_4, labels = str_c(
          "Labor union: ",
          c("Active member", "Inactive member", "Don't belong"))
        ), 
        str_c(
          "Labor union: ",
          c("Don't belong", "Inactive member", "Active member")
        )
      ),
      Q5.3_5 = fct_relevel(
        factor(Q5.3_5, labels = str_c(
          "Political party: ",
          c("Active member", "Inactive member", "Don't belong"))
        ), 
        str_c(
          "Political party: ",
          c("Don't belong", "Inactive member", "Active member")
        )
      ),
      Q5.3_6 = fct_relevel(
        factor(Q5.3_6, labels = str_c(
          "Environmental organization: ",
          c("Active member", "Inactive member", "Don't belong"))
        ), 
        str_c(
          "Environmental organization: ",
          c("Don't belong", "Inactive member", "Active member")
        )
      ),
      Q5.3_7 = fct_relevel(
        factor(Q5.3_7, labels = str_c(
          "Professional association: ",
          c("Active member", "Inactive member", "Don't belong"))
        ), 
        str_c(
          "Professional association: ",
          c("Don't belong", "Inactive member", "Active member")
        )
      ),
      Q5.3_8 = fct_relevel(
        factor(Q5.3_8, labels = str_c(
          "Humanitarian or charitable organization: ",
          c("Active member", "Inactive member", "Don't belong"))
        ), 
        str_c(
          "Humanitarian or charitable organization: ",
          c("Don't belong", "Inactive member", "Active member")
        )
      ),
      Q5.3_9 = fct_relevel(
        factor(Q5.3_9, labels = str_c(
          "Consumer organization: ",
          c("Active member", "Inactive member", "Don't belong"))
        ), 
        str_c(
          "Consumer organization: ",
          c("Don't belong", "Inactive member", "Active member")
        )
      ),
      Q5.3_10 = fct_relevel(
        factor(Q5.3_10, labels = str_c(
          "Other organization: ",
          c("Active member", "Inactive member", "Don't belong"))
        ), 
        str_c(
          "Other organization: ",
          c("Don't belong", "Inactive member", "Active member")
        )
      ),
      # *Q5.4*: Historically, how involved have you been in activist causes?
      # 
      # - Extremely involved → Involved
      # - Very involved → Involved
      # - Moderately involved → Involved
      # - Slightly involved → Not involved (base case)
      # - Never involved → Not involved
      Q5.4 = factor(
        case_when(
          Q5.4 == 1 ~ "Involved",
          Q5.4 == 2 ~ "Involved",
          Q5.4 == 3 ~ "Involved",
          Q5.4 == 4 ~ "Not involved",
          Q5.4 == 5 ~ "Not involved",
        ),
        levels = c("Not involved", "Involved"),
        labels = str_c(
          "History of activism: ",
          c("Not involved", "Involved")
        )
      ),
      # *Q5.5*: Historically, how involved has your family been in activist causes?
      # 
      # - Extremely involved → Involved
      # - Very involved → Involved
      # - Moderately involved → Involved
      # - Slightly involved → Not involved (base case)
      # - Never involved → Not involved
      Q5.5 = factor(
        case_when(
          Q5.5 == 1 ~ "Involved",
          Q5.5 == 2 ~ "Involved",
          Q5.5 == 3 ~ "Involved",
          Q5.5 == 4 ~ "Not involved",
          Q5.5 == 5 ~ "Not involved"
        ),
        levels = c("Not involved", "Involved"),
        labels = str_c(
          "History of family activism: ",
          c("Not involved", "Involved")
        )
      ),
      # *Q5.6*: On a scale of no trust (1) to complete trust (7), how much do you 
      # trust political institutions and the state?
      # 
      # - 1 (No trust)
      # - 2
      # - 3
      # - 4
      # - 5
      # - 6
      # - 7 (Complete trust)
      Q5.6 = factor(
        Q5.6,
        labels = str_c("Trust in political institutions: ",c(
          "No trust at all", "Very little trust", "Little trust", 
          "Neutral", "Some trust", "A lot of trust", "Complete trust"
        )),
        ordered = TRUE
      ),
      # *Q5.7*: Have you ever traveled to a developing country? 
      # 
      # - Yes
      # - No
      Q5.7 = fct_relevel(
        factor(Q5.7, labels = str_c("Traveled to a developing country: ", c("Yes", "No"))), 
        str_c("Traveled to a developing country: ", c("No", "Yes"))
      ),
      # *Q5.8*: How often do you attend religious or worship services, not including weddings and funerals?
      # 
      # - More than once a week → At least once a month
      # - Once a week → At least once a month
      # - Once or twice a month → At least once a month
      # - A few times a year → Rarely (base case)
      # - Seldom → Rarely
      # - Never → Rarely
      # - Don't know → Not sure
      Q5.8 = factor(
        case_when(
          Q5.8 == 1 ~ "At least once a month",
          Q5.8 == 2 ~ "At least once a month",
          Q5.8 == 3 ~ "At least once a month",
          Q5.8 == 4 ~ "Rarely",
          Q5.8 == 5 ~ "Rarely",
          Q5.8 == 6 ~ "Rarely",
          Q5.8 == 7 ~ "Not sure"
        ),
        levels = c("Not sure", "Rarely", "At least once a month"),
        labels = str_c(
          "Religious and worship service attendance: ",
          c("Not sure", "Rarely", "At least once a month")
        )
      ),
      # *Q5.9*: How important is religion in your life?
      # 
      # - Extremely important → Important
      # - Very important → Important
      # - Moderately important → Important
      # - Slightly important → Not important (base case)
      # - Not at all important → Not important
      Q5.9 = factor(
        case_when(
          Q5.9 == 1 ~ "Important",
          Q5.9 == 2 ~ "Important",
          Q5.9 == 3 ~ "Important",
          Q5.9 == 4 ~ "Not important",
          Q5.9 == 5 ~ "Not important"
        ),
        levels = c("Not important", "Important"),
        labels = str_c(
          "Importance of religion: ",
          c("Not important", "Important")
        )
      ),
      # *Q5.10*: What is your current religion, if any?
      # 
      # - Catholic (including Roman Catholic and Orthodox)
      # - Protestant (United Church of Canada, Anglican, Orthodox, Baptist, Lutheran)
      # - Christian Orthodox
      # - Jewish
      # - Muslim
      # - Sikh
      # - Hindu
      # - Buddhist
      # - Atheist (do not believe in God)
      # - Other: _________
      Q5.10 = factor(
        Q5.10, 
        labels = str_c("Religion: ", c(
          "Catholic", "Protestant", "Christian Orthodox", "Jewish", 
          "Muslim", "Sikh", "Hindu", "Buddhist", "Atheist", "Other")), 
        ordered = TRUE
      ),
      # *Q5.11*: On a scale of strongly agree (1) to strongly disagree (7), rate your response to the 
      # following statement: People should be more charitable towards others in society.
      # 
      # - 1 (Strongly agree)
      # - 2
      # - 3
      # - 4
      # - 5
      # - 6
      # - 7 (Strongly disagree)
      Q5.11 = fct_relevel(
        factor(
          Q5.11,
          labels = str_c("People should be more charitable: ", c(
            "Strongly agree", "Agree", "Somewhat agree", 
            "Neutral", "Somewhat disagree", "Disagree", "Strongly disagree"
          ))
        ),
        str_c("People should be more charitable: ", c(
          "Strongly disagree", "Disagree", "Somewhat disagree",
          "Neutral", "Somewhat agree", "Agree", "Strongly agree"
        ))
      ),
      # *Q5.12*: What is your gender?
      # 
      # - Male
      # - Female
      # - Transgender
      # - Prefer not to say
      # - Other: _________
      Q5.12 = factor(
        Q5.12, 
        labels = str_c("Gender: ", c(
          "Male", "Female", "Transgender", 
          "Prefer not to say", "Other"
        )), 
        ordered = TRUE
      ),
      # *Q5.13*: Are you now married, widowed, divorced, separated, or never married?
      # 
      # - Married
      # - Widowed
      # - Divorced
      # - Separated
      # - Never married
      Q5.13 = factor(
        Q5.13, 
        labels = str_c("Marital status: ", c(
          "Married", "Widowed", "Divorced", 
          "Separated", "Never married"
        )), 
        ordered = TRUE
      ),
      # *Q5.14*: What is the highest degree or level of school you have completed?
      # 
      # - Less than high school
      # - High school graduate
      # - Some college
      # - 2 year degree
      # - 4 year degree 
      # - Graduate or professional degree
      # - Doctorate
      Q5.14 = factor(
        Q5.14, 
        labels = str_c("Education: ", c(
          "Less than high school", "High school graduate", 
          "Some college", "2 year degree", "4 year degree", 
          "Graduate or professional degree", "Doctorate"
        )),
        ordered = TRUE
      ),
      # *Q5.15*: What is your annual household income before taxes?
      # 
      # - Less than $10,000 → More/less than median (base case = less than median)
      # - $10,000 to $19,999 → More/less than median
      # - $20,000 to $29,999 → More/less than median
      # - $30,000 to $39,999 → More/less than median
      # - $40,000 to $49,999 → More/less than median
      # - $50,000 to $59,999 → More/less than median
      # - $60,000 to $69,999 → More/less than median
      # - $70,000 to $79,999 → More/less than median
      # - $80,000 to $89,999 → More/less than median
      # - $90,000 to $99,999 → More/less than median
      # - $100,000 to $149,999 → More/less than median
      # - $150,000 to $199,999 → More/less than median
      # - $200,000 to $299,999 → More/less than median
      # - $300,000 or more → More/less than median
      Q5.15 = factor(
        case_when(
          Q5.15 > 5 ~ "More than median", # Median income in 2017 was $61,372
          Q5.15 <= 5 ~ "Less than median"
        ),
        levels = c("Less than median", "More than median"),
        labels = str_c(
          "Income: ",
          c("Less than median", "More than median")
        )
      )
    ) %>% 
    mutate(
      # *Q5.16*: Choose one or more races that you consider yourself to be:
      # 
      # - White
      # - Black or African American
      # - American Indian or Alaska Native
      # - Asian
      # - Native Hawaiian or Pacific Islander
      # - Other: _________
      across(contains("Q5.16"), ~coalesce(.x, 0))
    ) %>% 
    mutate(
      Q5.16_1 = factor(Q5.16_1, labels = str_c("Race: ", c("Not White", "White"))),
      Q5.16_2 = factor(Q5.16_2, labels = str_c(
        "Race: ", c("Not Black or African American", "Black or African American"))
      ),
      Q5.16_3 = factor(Q5.16_3, labels = str_c(
        "Race: ", c("Not American Indian or Alaska Native", "American Indian or Alaska Native"))
      ),
      Q5.16_4 = factor(Q5.16_4, labels = str_c("Race: ", c("Not Asian", "Asian"))),
      Q5.16_5 = factor(Q5.16_5, labels = str_c(
        "Race: ", 
        c("Not Native Hawaiian or Pacific Islander", "Native Hawaiian or Pacific Islander")
      )),
      Q5.16_6 = factor(Q5.16_6, labels = str_c("Race: ", c("Not Other", "Other"))),
      # *Q5.17*: How old are you?
      # 
      # - Under 18 → More/less than median (base case = less than median)
      # - 18 - 24 → More/less than median
      # - 25 - 34 → More/less than median
      # - 35 - 44 → More/less than median
      # - 45 - 54 → More/less than median
      # - 55 - 64 → More/less than median
      # - 65 - 74 → More/less than median
      # - 75 - 84 → More/less than median
      # - 85 or older → More/less than median
      Q5.17 = factor(
        case_when(
          Q5.17 >= 3 ~ "More than median", # Median age in 2017 was 36
          Q5.17 < 3 ~ "Less than median"
        ),
        levels = c("Less than median", "More than median"),
        labels = str_c(
          "Age: ", 
          c("Less than median", "More than median")
        )
      )
    )
  
  
  # Create a wide design matrix dataset with a column per feature (so 6 columns).
  # This represents 130 different possible versions, with 12 choice sets, 3
  # choices, and 6 features (130*12*3*6 = 28,080); when widened so there's one
  # column per feature, this turns into 4680 rows (28080/6)
  design <- data_eligible %>% 
    select(contains("CBCONJOINT"), -revision_CBCONJOINT) %>% 
    pivot_longer(-vers_CBCONJOINT, names_to = "temp", values_to = "level_names") %>% 
    separate(temp, into = c("atts", "task", "alt"), sep = "\\.") %>% 
    separate(alt, into = c("alt", "temp")) %>% 
    select(vers_CBCONJOINT, task, alt, atts, level_names) %>% 
    rename(version = vers_CBCONJOINT) %>% 
    mutate(
      task = as.numeric(task),
      alt = as.numeric(alt),
      atts = recode(
        atts,
        "732d72a6-25a3-4194-8416-461acae30837" = "Organization",
        "bd54b90a-efb3-4ac8-b65a-1ebeefcaf703" = "Issue area",
        "a6836e28-fd7a-4b71-b65e-f6269e5c883f" = "Financial transparency",
        "c2249c1a-11fa-4395-a0a3-61d9648a2e55" = "Accountability",
        "db44c406-390e-4fc4-875b-65796aa95ffa" = "Funding sources",
        "85f14c50-61cc-461c-8e77-19453b83d76d" = "Relationship with host government"
      )
    ) %>%
    distinct() %>% 
    arrange(version, task, alt) %>% 
    pivot_wider(names_from = atts, values_from = level_names)
  
  
  # Extract small dataset of the actual conjoint choices made by each person. 
  # This has 12 rows per individual, so 1,016 * 12 = 12,192
  choices <- data_clean %>% 
    select(id, Q4.1:Q4.12) %>% 
    pivot_longer(cols = starts_with("Q4"), names_to = "task", values_to = "choice") %>% 
    mutate(
      task = as.numeric(str_remove(task, "Q4\\.")),
      choice = case_match(choice, 4 ~ 0, .default = choice)
    ) 
  
  # Create final long data with conjoint options and choices merged into the full
  # clean data This will have 36 rows per individual (12 tasks, 3 options in each
  # task), so 1,016 * 36 = 36,576
  data_final <- data_clean %>%
    # Merge in conjoint design and conjoint choices
    full_join(design, by = join_by(version), relationship = "many-to-many") %>%
    left_join(choices, by = join_by(id, task)) %>%
    
    # Clean up feature columns
    rename(
      feat_org = Organization,
      feat_issue = `Issue area`,
      feat_transp = `Financial transparency`,
      feat_acc = Accountability,
      feat_funding = `Funding sources`,
      feat_govt = `Relationship with host government`
    ) %>%
    mutate(
      feat_org = factor(feat_org,
        levels = c("Amnesty International", "Greenpeace", "Oxfam", "Red Cross")
      ),
      feat_issue = factor(feat_issue,
        levels = c("Emergency response", "Environment", "Human rights", "Refugee relief")
      ),
      feat_transp = factor(feat_transp, levels = c("No", "Yes")),
      feat_acc = factor(feat_acc, levels = c("No", "Yes")),
      feat_funding = factor(feat_funding,
        levels = c(
          "Funded primarily by many small private donations",
          "Funded primarily by a handful of wealthy private donors",
          "Funded primarily by government grants"
        )
      ),
      feat_govt = factor(feat_govt,
        levels = c(
          "Friendly relationship with government",
          "Criticized by government",
          "Under government crackdown"
        )
      ),
      # Make the levels for transparency and accountability unique
      feat_transp = fct_recode(feat_transp,
        "Transparency: No" = "No",
        "Transparency: Yes" = "Yes"
      ),
      feat_acc = fct_recode(feat_acc,
        "Accountability: No" = "No",
        "Accountability: Yes" = "Yes"
      )
    ) %>% 
    
    # Add choice columns
    #   This is the same for the whole task (so if a respondent chose option 2 in
    #   task 1, all three rows would be "2")
    mutate(choice = factor(choice)) %>%
    #   This is a 0/1 value for the individual choice (so if a respondent chose
    #   option 2 in task 1, the three rows would be "0", "1", and "0")
    mutate(choice_binary = ifelse(choice == alt, 1, 0)) %>%
    #   This is a 0/1/2/3 value for the individual choice (so if a respondent
    #   chose option 2 in task 1, the three rows would be "0", "2", and "0")
    mutate(choice_alt = factor(alt * choice_binary))
  
  return(lst(data_clean, data_final))
}
