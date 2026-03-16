// File: test/helpers_test.go
package test

import (
	"fmt"
	"math/rand"
	"os"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

// mustEnv returns the value of a required environment variable or fails the test.
func mustEnv(t *testing.T, key string) string {
	t.Helper()
	v := strings.TrimSpace(os.Getenv(key))
	require.NotEmpty(t, v, "Missing required environment variable %s", key)
	return v
}

// mustEnvOptional returns the value of an optional environment variable,
// returning an empty string if unset.
func mustEnvOptional(key string) string {
	return strings.TrimSpace(os.Getenv(key))
}

// randomProjectSuffix generates a 4-character random suffix for unique project IDs.
// Length is capped at 4 to stay within GCP's 30-character project ID limit when
// appended (with a dash) to the longest base ID used in tests.
func randomProjectSuffix() string {
	const chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, 4)
	for i := range b {
		b[i] = chars[rand.Intn(len(chars))]
	}
	return string(b)
}

// assertOutputKeyPresent asserts that a key exists in the output map and is non-empty.
func assertOutputKeyPresent(t *testing.T, outputMap map[string]string, key, label string) {
	t.Helper()
	val, ok := outputMap[key]
	require.True(t, ok, "Expected %s %q to be present in outputs", label, key)
	require.NotEmpty(t, val, "Expected %s %q to have a non-empty value", label, key)
}

// assertServiceEnabled asserts that "projectKey/service" is present in the
// enabled_services output map.
func assertServiceEnabled(t *testing.T, servicesMap map[string]string, projectKey, service string) {
	t.Helper()
	compositeKey := fmt.Sprintf("%s/%s", projectKey, service)
	val, ok := servicesMap[compositeKey]
	require.True(t, ok, "Expected service %q to be enabled for project %q", service, projectKey)
	require.Equal(t, service, val,
		"Service name mismatch for %q in project %q", service, projectKey)
}
