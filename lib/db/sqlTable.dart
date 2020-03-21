class SqlTable{
  static final String sqlCreateTableTasks = """
  CREATE TABLE tasks(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    taskId TEXT NOT NULL UNIQUE,
    date INTEGER NOT NULL
  );
  """;
  static final String sqlCreateTablePoints = """
    CREATE TABLE points (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      taskId TEXT,
      lat REAL NOT NULL,
      lng REAL NOT NULL,
      locationType INTEGER,
      accuracy REAL,
      address TEXT,
      country TEXT,
      province TEXT,
      city TEXT,
      district TEXT,
      street TEXT,
      streetNum TEXT,
      cityCode TEXT,
      adCode TEXT,
      aoiName TEXT,
      buildingId TEXT,
      floor TEXT,
      gpsAccuracyStatus INTEGER,
      bearing REAL,
      conScenario INTEGER,
      speed REAL,
      trustedLevel INTEGER,
      coordType TEXT,
      statellites INTEGER,
      time INTEGER
    );
    """;
}