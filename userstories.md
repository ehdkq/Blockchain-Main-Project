# 1. **Farmer – Crop Monitoring & Trustworthy Data**
- **As a** farmer, **I want to** monitor real-time soil and weather data from IoT sensors, **so that** I can make informed decisions about irrigation and fertilization.
- Given an active IoT sensor is connected,
When the farmer opens the dashboard,
Then the system displays current soil moisture, temperature, and weather conditions.
- **As a** farmer, **I want to** store environmental sensor data immutably on the blockchain, **so that** I can verify that the data is accurate and hasn’t been tampered with.
- Given IoT sensor data is generated,
When it is submitted to the blockchain,
Then the system records it with a timestamp and prevents future edits or deletions.
- **As a** farmer, **I want to** track the full lifecycle of crops (from seeding to harvest) using blockchain-backed records, **so that** I can prove the quality and origin of my produce to buyers.
- Given a farmer logs a crop event (seeding, fertilizing, harvest),
When the event is submitted,
Then the blockchain records it immutably with time and date,
And buyers can later view the full lifecycle record.

# 2. **Agricultural Scientist / Researcher – Data Analysis**
- **As a** researcher, **I want to** access historical sensor data stored on the blockchain, **so that** I can analyze environmental trends without worrying about data manipulation.
- Given historical IoT data is stored on the blockchain,
When a researcher queries by date range,
Then the system returns the correct records with matching blockchain hashes.
- **As a** researcher, **I want to** verify the source and integrity of agricultural data, **so that** my research is based on reliable information.
- Given a dataset is retrieved,
When the researcher requests verification,
Then the system displays the source device ID, farm identity, and blockchain signature.

# 3. **Supply Chain Manager – Traceability**
- **As a** supply chain manager, **I want to** trace the journey of agricultural products from farm to market via blockchain records, **so that** I can ensure transparency and trust for consumers.
- Given each supply chain stage is recorded (farm, transport, storage, retail),
When a manager requests a traceability report,
Then the system outputs the full journey,
And missing stages trigger a “trace incomplete” warning.
- **As a** supply chain manager, **I want to** get alerts if any IoT sensor data (like temperature during transport) deviates from the norm, **so that** I can take timely action to reduce spoilage.
- Given transport sensors are active,
When temperature or humidity values deviate from thresholds,
Then the system sends an alert within X minutes,
And logs the event immutably on the blockchain.

# 4. **Consumer – Trust in Food Source**
- **As a** consumer, **I want to** scan a QR code on a product and see its blockchain-verified origin, **so that** I can trust its quality and safety.
- Given a consumer scans a product’s QR code,
When the system retrieves blockchain data,
Then it displays the product’s farm origin, certification, and timestamped details.
- **As a** consumer, **I want to** verify that a product was grown under ethical and sustainable conditions, **so that** I can make informed purchasing decisions.
- Given a product has sustainability or ethical certifications,
When a consumer views its blockchain record,
Then certifications and supporting evidence are displayed,
And if unavailable, the system shows “not verified.”

# 5. **System Administrator – Security and Access Control**
- **As a** DAO, **I want to** manage permissions for IoT devices using on-chain voting or smart contract logic, **so that** only verified devices can submit trusted data.
- Given a DAO manages device permissions,
When members vote to approve or remove a device,
Then only verified devices may submit data,
And unverified submissions are rejected.
- **As a** DAO, **I want to** automatically trigger alerts or actions when smart contracts detect abnormal data patterns, **so that** the network remains secure without centralized oversight.
- Given anomaly detection rules are configured in a smart contract,
When incoming data exceeds these rules,
Then the system automatically triggers alerts,
And optionally pauses further submissions until reviewed.

# 6. **IoT Device (Automated Interaction – Optional)**
- **As an** IoT sensor device, **I want to** automatically send temperature and humidity data every 10 minutes, **so that** farmers receive up-to-date insights.
- Given a sensor is connected,
When 10 minutes have passed,
Then the sensor automatically transmits temperature and humidity data,
And the farmer dashboard updates within 1–2 minutes.
- **As an** IoT gateway, **I want to** batch sensor data and commit it to the blockchain every hour, **so that** data is stored efficiently and securely.
- Given multiple sensor readings are collected,
When the gateway reaches the one-hour mark,
Then the system batches the readings into a single transaction,
And stores the batch hash and timestamp on the blockchain.
