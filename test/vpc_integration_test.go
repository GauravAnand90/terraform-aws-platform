// Package test holds Terratest integration tests. Unlike the mocked `terraform test`
// suite, these deploy real AWS resources, assert on them, and destroy them.
//
// They are opt-in because they cost money (a NAT gateway for a few minutes):
//
//	RUN_INTEGRATION=1 AWS_PROFILE=sandbox go test -v -timeout 30m ./...
package test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const region = "us-west-2"

func TestVPCModule(t *testing.T) {
	if os.Getenv("RUN_INTEGRATION") != "1" {
		t.Skip("set RUN_INTEGRATION=1 to run tests that create real AWS resources")
	}
	t.Parallel()

	name := fmt.Sprintf("tt-%s", strings.ToLower(random.UniqueId()))

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./fixtures/vpc",
		Vars: map[string]interface{}{
			"name":   name,
			"region": region,
		},
	})

	// Always clean up, even when an assertion fails.
	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	vpcID := terraform.Output(t, opts, "vpc_id")
	privateSubnets := terraform.OutputList(t, opts, "private_subnet_ids")
	databaseSubnets := terraform.OutputList(t, opts, "database_subnet_ids")

	require.Len(t, privateSubnets, 2)
	require.Len(t, databaseSubnets, 2)

	// Private subnets must not hand out public IPs.
	for _, id := range privateSubnets {
		assert.False(t, aws.IsPublicSubnet(t, id, region), "private subnet %s has a route to an internet gateway", id)
	}

	// Database subnets must have no internet path at all.
	for _, id := range databaseSubnets {
		assert.False(t, aws.IsPublicSubnet(t, id, region), "database subnet %s has a route to an internet gateway", id)
	}

	vpc := aws.GetVpcById(t, vpcID, region)
	assert.Equal(t, name, vpc.Name)
}
