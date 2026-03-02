package services

// CalculateVariance checks if we lost too much oil during bottling
func CalculateVariance(litersUsed float64, bottleSize float64, actualCount int) (float64, string) {
	expectedCount := litersUsed / bottleSize
	// Calculate % difference
	variance := ((expectedCount - float64(actualCount)) / expectedCount) * 100

	status := "Within Threshold"
	if variance > 0.5 { // Flag if loss is over 0.5%
		status = "WARNING: High Variance Detected"
	}

	return variance, status
}
