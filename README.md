# Bank Marketing Analytics
## Project Background
This portfolio project leverages predictive analytical methods to assess the driving factors influencing the success of telemarketing campaigns made by a Portuguese banking institution. The marketing campaigns were telephone-based and spanned years 2008 to 2013. Often, more than one correspondence attempt to the same client was made to determine whether the product (the bank long-term deposit) would be ('yes') or would not be ('no') sold. Interested readers can visit the following link to learn more about the dataset: [https://archive.ics.uci.edu/dataset/222/bank+marketing](https://archive.ics.uci.edu/dataset/222/bank+marketing). This project concludes with insights and recommendations on areas of the bank's marketing approach that could be improved to convert more sales of deposits in the future. 

The R-Script utilized for all analyses can be downloaded [here](https://github.com/Ellis-Kalaidjian/bank_marketing_analytics/blob/main/bank_marketing_analytics.R).

## Data Structure and Sample Composition
This dataset contains 41,188 observations grouped over 21 variables of categorical, numeric, and binary classes. These include telemarketing attributes (e.g., contact method type) and client information (e.g., age and occupation type). These records were enriched with social and economic influence features (e.g., interbank interest rates and unemployment variation rate), by gathering external data from the central bank of the Portuguese Republic statistical website.

<img width="540" alt="image" src="https://github.com/user-attachments/assets/d8fd5227-3525-43b6-82af-fdd9d14963e3" />

The sample exhibits a median age of 38 years old, with a majority of subjects (26,588) classified as "adult" (ages 26-44). Most subjects are married (24,928), work in administrative roles (10,422), and hold university degrees (12,168). Additionally, most have credit in default (32,588), a housing loan (21,576), and a personal loan (33,950). A distribution of age and job type is provided in the figure below.

<img width="432" alt="image" src="https://github.com/user-attachments/assets/a3e5072c-67c8-4f1a-885c-a342630c2ad8" />

## Executive Summary
With the goal of identifying key drivers of campaign success in mind, two supervised machine learning algorithms were used and compared: logistic regression and random forest classification. While the performance of both models was strong, the random forest classification was determined to have a more accurate predictive capacity (interested readers can find a more thorough discussion of how models were compared [here](https://github.com/Ellis-Kalaidjian/bank_marketing_analytics/blob/main/bank_marketing_analysis_model_comparison_readME.docx)).

It was determined that single most important determinant of whether or not the marketing campaign succeeded was the length of correspondence time. Every 1-minute increase in time spent on the phone increased the odds of the respondent buying the bank long-term deposit by 30%. Other notable determinants of campaign success were the proxies for prevailing macroeconomic conditions---the 3-month Euribor rate, an economic indicator that indirectly influences banks’ interest rates and, hence, purchasing behavior; the consumer confidence index; consumer price index; and employment variation rate---along with the number of days that passed by after the client was last contacted from a previous campaign.


## Insights and Recommendations
Based on the results of the model, the folllowing five actions are recommended as follows:

**Insight #1: Call Duration Is the Strongest Predictor**
Longer calls are strongly associated with positive responses. One caveat with this predictor is that, since duration is only known post-call, it's not useful for targeting before contact. Nonetheless, it’s a strong indicator of lead interest. If the goal of the bank's marketing team is selecting leads, another model could be trained without including "duration" as a variable. Otherwise, the primary recommendation is to use duration for post-call scoring---that is, if a lead stays on longer, prioritize for follow-up.

**Insight #2: Macroeconomic Indicators Strongly Influence Outcomes**
Customers respond better during favorable economic periods (e.g., low unemployment, high consumer confidence). In light of this finding, the marketing team should time campaigns during periods of economic optimism. Additionally, it may be opportune to align offers or messaging to current macroeconomic trends (e.g., “Now is the best time to invest/save...” during low interest rate periods).

**Insight #3: Contact Strategy Matters**
The communication channel and month of contact were found to influence conversion rates. Further investigation into home telephone versus cellular phone superiority in converting sales should be executed. Further, the team should analyze performance by month to find seasonal peaks and run campaigns during those months.

**Insight #4: Past Campaign Response (poutcome_code) Is Predictive**
Clients who responded positively in the past are more likely to do so again. The team could use the "poutcome" variable to create a "hot lead" segment. Then, through this effort, the team can prioritize follow-up with those who previously subscribed or engaged.

**Insight #5: Client Profile Variables Have Modest But Notable Impact**
While variables like occupation, education level, marital status, and having a house loan were weaker, they are still informative. One insight to glean from this finding is that certain demographics may respond more positively. Further efforts to, for instance, build customer profiles via customer segmentation methods could aid targeting or personalized messaging (e.g., the marketing team could tailor investment product messaging differently to students vs. retirees).
