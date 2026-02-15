<?php
// Database Config
$host = "localhost";
$username = "root";
$password = "200413"; // Password from your config
$dbname = "smart_farm_db"; // Database name

// Connect to MySQL
$conn = new mysqli($host, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Fetch Data
$sql = "SELECT * FROM thingspeak_logs ORDER BY created_at DESC LIMIT 50";
$result = $conn->query($sql);

?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Smart Farm Dashboard</title>
    <!-- Bootstrap CSS for nice styling -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; }
        .container { margin-top: 30px; }
        .card { box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .table-responsive { max-height: 500px; }
        .header-title { color: #198754; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="row mb-4">
            <div class="col text-center">
                <h1 class="header-title">🌱 Smart Farm Data Logs</h1>
                <p class="text-muted">Synced from ThingSpeak to MySQL</p>
            </div>
        </div>

        <div class="card">
            <div class="card-header bg-success text-white">
                <i class="bi bi-table"></i> Latest Sensor Readings
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-striped table-hover">
                        <thead class="table-dark">
                            <tr>
                                <th>ID</th>
                                <th>Time</th>
                                <th>Air Temp (°C)</th>
                                <th>Humidity (%)</th>
                                <th>Leaf Temp (°C)</th>
                                <th>Lux</th>
                                <th>Pump</th>
                                <th>Light</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if ($result->num_rows > 0): ?>
                                <?php while($row = $result->fetch_assoc()): ?>
                                    <tr>
                                        <td><?php echo $row["entry_id"]; ?></td>
                                        <td><?php echo $row["created_at"]; ?></td>
                                        <td><?php echo $row["air_temp"]; ?></td>
                                        <td><?php echo $row["humidity"]; ?></td>
                                        <td><?php echo $row["leaf_temp"]; ?></td>
                                        <td><?php echo number_format($row["lux"], 0); ?></td>
                                        <td>
                                            <span class="badge bg-<?php echo $row["pump_status"] ? 'primary' : 'secondary'; ?>">
                                                <?php echo $row["pump_status"] ? 'ON' : 'OFF'; ?>
                                            </span>
                                        </td>
                                        <td>
                                            <span class="badge bg-<?php echo $row["light_status"] ? 'warning' : 'secondary'; ?>">
                                                <?php echo $row["light_status"] ? 'ON' : 'OFF'; ?>
                                            </span>
                                        </td>
                                    </tr>
                                <?php endwhile; ?>
                            <?php else: ?>
                                <tr><td colspan="8" class="text-center">No data found</td></tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</body>
</html>

<?php
$conn->close();
?>
