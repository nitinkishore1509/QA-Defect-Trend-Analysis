# 📊 Defect Trend Analysis & Prediction for QA in IT Projects

## 🔹 Project Overview

In IT projects, **defect management** is one of the most critical quality metrics.
QA managers often struggle with questions like:

* Which modules are **most defect-prone**?
* Are **critical defects** being resolved on time?
* Is the **defect backlog** increasing or shrinking?
* Can we **predict defect trends** to plan resources better?

This project addresses these challenges by building a **data analytics solution** in **Power BI** and **SQL**, using a dataset of 5000 software defects logged during IT projects.

---

## 🔹 Objectives

1. Perform **Defect Trend Analysis** by module, severity, and timeline.
2. Monitor **Backlog Growth** and **Closure Rates**.
3. Measure **Resolution Time** and SLA compliance.
4. Provide **interactive dashboards** for QA managers.
5. Build a **predictive model** for defect trends (future backlog estimation).

---

## 🔹 Dataset

* **File:** `Processed_QA_Defects.csv`
* **Rows:** 5000 defects
* **Key Columns:**

  * `Defect_ID` → Unique identifier
  * `Module` → Component/application area
  * `Severity` → Critical / High / Medium / Low
  * `Status` → Open / Closed / In Progress / Deferred
  * `Created_Date`, `Closed_Date`
  * `Resolution_Time (days)`

---

## 🔹 Approach & Methodology

### 1. **Data Preparation**

* Converted `Created_Date` & `Closed_Date` → Date/Time format.
* Derived **Resolution\_Time (days)** = difference between Created & Closed.
* Preserved missing values → open defects not closed yet.
* Verified consistency in `Severity` and `Status` fields.

### 2. **Power BI Dashboard**

Created **DAX measures** for industry-standard QA KPIs:

* **Total Defects**
* **Open vs Closed Defects**
* **Closure Rate %**
* **Avg Resolution Time**
* **Cumulative Created / Closed / Backlog**
* **Defects by Severity & Module**
* **SLA Compliance %**

📊 **Visuals Designed:**

* **KPI Cards** → Total Defects, Open Defects, Closure Rate %, Avg Resolution Time.
* **Donut Chart** → Severity Distribution.
* **Bar Chart** → Defects by Module.
* **Matrix Heatmap** → Module × Severity defect density.
* **Line Chart** → Defects Created vs Closed over Time.
* **Area Chart** → Backlog Trend.

### 3. **Predictive Analysis (Python)**

* Built a **time-series model** to forecast defect backlog.
* Used **Prophet / ARIMA** to predict defect closure vs creation trend.
* Visualized future backlog growth.

---

## 🔹 Insights Generated

* **Critical defects** had the longest resolution times → SLA breaches.
* Certain **modules consistently showed high defect density** → weak development areas.
* **Backlog trend spiked during release phases** → testing bottlenecks.
* **Closure rate dipped below 85%** in some sprints → required team intervention.
* Predictive model indicated a **potential 12% increase in backlog** if no resource adjustment is made.

---

## 🔹 Business Impact

* Helped QA managers **prioritize high-risk modules**.
* Supported **data-driven resource allocation**.
* Improved **closure efficiency** by monitoring SLA breaches.
* Enabled **proactive planning** using defect trend forecasts.

---

## 🔹 Tools & Technologies

* **Power BI** → Dashboard & Visualization
* **DAX** → Business KPIs & Trend Measures
* **GitHub** → Project Documentation



---

## 🔹 Future Enhancements

* Integrate **real-time defect logs** from Jira/ServiceNow API.
* Enhance prediction model with **Random Forest / Gradient Boosting**.
* Add \*\*automated SLA breach alerts
