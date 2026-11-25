#!/bin/bash
set -euo pipefail

# Azure Configuration
SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Replace with your Azure subscription ID
LOCATION="southindia"
RG="demo-vnet-azure"

# VNet
VNET="vnet-demo-dev-sindia-001"
VNET_CIDR="10.0.0.0/16"

# Subnets
PUBLIC_SUBNET="snet-demo-dev-public-sindia-001"
PUBLIC_CIDR="10.0.1.0/24"

PRIVATE_SUBNET="snet-demo-dev-private-sindia-001"
PRIVATE_CIDR="10.0.2.0/24"

# Route Tables
PUBLIC_RT="rt-demo-dev-public-sindia-001"
PRIVATE_RT="rt-demo-dev-private-sindia-001"

# NSGs
PUBLIC_NSG="nsg-demo-dev-public-sindia-001"
PRIVATE_NSG="nsg-demo-dev-private-sindia-001"

echo "Selecting Azure subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

echo "Checking Resource Group..."
az group show -n "$RG" -o table

# 1. Create VNet
echo "Creating VNet..."

az network vnet create \
  -g "$RG" \
  -n "$VNET" \
  -l "$LOCATION" \
  --address-prefixes "$VNET_CIDR"

# 2. Create Public Subnet
echo "Creating Public Subnet..."

az network vnet subnet create \
  -g "$RG" \
  --vnet-name "$VNET" \
  -n "$PUBLIC_SUBNET" \
  --address-prefixes "$PUBLIC_CIDR"

# 3. Create Private Subnet
echo "Creating Private Subnet..."

az network vnet subnet create \
  -g "$RG" \
  --vnet-name "$VNET" \
  -n "$PRIVATE_SUBNET" \
  --address-prefixes "$PRIVATE_CIDR"

# 4. Create Public Route Table
echo "Creating Public Route Table..."

az network route-table create \
  -g "$RG" \
  -n "$PUBLIC_RT" \
  -l "$LOCATION"

# 5. Create Private Route Table
echo "Creating Private Route Table..."

az network route-table create \
  -g "$RG" \
  -n "$PRIVATE_RT" \
  -l "$LOCATION"

# 6. Configure Public Internet Route
echo "Configuring Public Internet Route..."

az network route-table route create \
  -g "$RG" \
  --route-table-name "$PUBLIC_RT" \
  -n "route-to-internet" \
  --address-prefix "0.0.0.0/0" \
  --next-hop-type Internet

# Private route table intentionally has no custom routes.

# 7. Associate Public Route Table
echo "Associating Public Route Table..."

az network vnet subnet update \
  -g "$RG" \
  --vnet-name "$VNET" \
  -n "$PUBLIC_SUBNET" \
  --route-table "$PUBLIC_RT"

# 8. Associate Private Route Table
echo "Associating Private Route Table..."

az network vnet subnet update \
  -g "$RG" \
  --vnet-name "$VNET" \
  -n "$PRIVATE_SUBNET" \
  --route-table "$PRIVATE_RT"

# 9. Create Public NSG
echo "Creating Public NSG..."

az network nsg create \
  -g "$RG" \
  -n "$PUBLIC_NSG" \
  -l "$LOCATION"

# 10. Create Private NSG
echo "Creating Private NSG..."

az network nsg create \
  -g "$RG" \
  -n "$PRIVATE_NSG" \
  -l "$LOCATION"

# 11. Get your public IP for SSH restriction
MY_IP=$(curl -4 -s https://api.ipify.org)

echo "Your public IP: $MY_IP"

# 12. Public NSG - Allow SSH from your IP
az network nsg rule create \
  -g "$RG" \
  --nsg-name "$PUBLIC_NSG" \
  -n "Allow-SSH-From-My-IP" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "$MY_IP/32" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 22

# 13. Private NSG - Allow SSH from Public Subnet
az network nsg rule create \
  -g "$RG" \
  --nsg-name "$PRIVATE_NSG" \
  -n "Allow-SSH-From-Public-Subnet" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "$PUBLIC_CIDR" \
  --source-port-ranges "*" \
  --destination-address-prefixes "$PRIVATE_CIDR" \
  --destination-port-ranges 22

# 14. Associate Public NSG
az network vnet subnet update \
  -g "$RG" \
  --vnet-name "$VNET" \
  -n "$PUBLIC_SUBNET" \
  --network-security-group "$PUBLIC_NSG"

# 15. Associate Private NSG
az network vnet subnet update \
  -g "$RG" \
  --vnet-name "$VNET" \
  -n "$PRIVATE_SUBNET" \
  --network-security-group "$PRIVATE_NSG"

echo "======================================"
echo " PHASE 1 COMPLETED"
echo " Azure Network Infrastructure Created"
echo "======================================"

echo "VNet:"
az network vnet show \
  -g "$RG" -n "$VNET" -o table

echo "Subnets:"
az network vnet subnet list \
  -g "$RG" --vnet-name "$VNET" -o table

echo "Route Tables:"
az network route-table list \
  -g "$RG" -o table

echo "Network Security Groups:"
az network nsg list \
  -g "$RG" -o table

echo "All Resources:"
az resource list \
  -g "$RG" -o table

echo "Phase 1 successfully completed."
echo "No virtual machines have been created."