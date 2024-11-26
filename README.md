# Liverpool Natural History Museum: Plant Health Monitoring System
<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
      <a href="#env-tfvars-requirements">.env & .tfvars Requirements</a>
      <a href="#folders-explained">Files Explained</a>
      <a href="#files-explained">Folders Explained</a>
  </ol>
</details>

## About the Project
Liverpool Natural History Museum (LNMH) employs an array of Raspberry Pi sensors to monitor critical plant health metrics such as soil moisture and temperature across their conservatory. However, the museum is seeking to enhance its monitoring system by tracking the health of plants over time and providing real-time alerts for gardeners when there is a problem. This project delivers a fully-functioning cloud-based Extract Transform Load (ETL) pipeline incorporating short- and long-term data storage solutions. In addition, the project includes a dynamic dashboard which allows staff constant access to a source of continually updating information.  

### Built With
 [![Python][Python.com]][Python-url]


## 🛠️ Getting Started
Prerequisites:
- Python 3.x must be installed with pip3 for dependency installation.  


## Installation
1. Clone the repository to your local machine using the following command:
   ```sh
   git clone https://github.com/SurinaCS/Coursework-Data-Engineering-Week-5.git
   ```
2. Navigate into the cloned repository.
3. Install all required dependencies:
   ```sh
   pip install -r requirements.txt
   ```
## .env & .tfvars Requirements
You must have a `.env` file containing:   
| Variable Name       | Description          | 
| ------------- |:-------------:| 
| AWS_ACCESS_KEY_ID      | Part of an access key pair that allows access to AWS resources and API calls. | 
| AWS_SECRET_ACCESS_KEY      | Private key used to access AWS resources.      |  

   
## Folders Explained
These folders are found this repository:     
<<<<<<< HEAD
- **[archive](https://github.com/SurinaCS/lmnh-plant-sensors/tree/main/archive)**     
   This folder contains the necessary files to move the data extracted from the previous 24hrs to the S3 bucket where 'archived' data is stored.
- **[dashboard](https://github.com/SurinaCS/lmnh-plant-sensors/tree/main/dashboard)**
  This folder contains the scripts needed to create the dashboard, showing dynamic visualisations on plant health for the staff to access.

- **[pipeline](https://github.com/SurinaCS/lmnh-plant-sensors/tree/main/pipeline)**
  This folder contains the ETL pipeline scripts including:
    - _Extract_: Fetching the data from the API endpoint (https://data-eng-plants-api.herokuapp.com/plants/49) every minute for all plants.
    - _Load_: Cleans data to ensure reliability (mitigate impact of faulty sensors).
    - _Transform_: Loads the last 24 hours of data into a Microsoft SQL Server Database (RDS).

- **[terraform](https://github.com/SurinaCS/lmnh-plant-sensors/tree/main/terraform)**

## Files Explained
These files are found in this repository:
- **README.md**  
  This is the file you are currently reading, containing information about each file.   
- **requirements.txt**  
  This project requires specific Python libraries to run correctly. These dependencies are listed in this file and are needed to ensure your environment matches the project's environment requirements.


[Python.com]: https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54
[Python-url]: https://www.python.org/