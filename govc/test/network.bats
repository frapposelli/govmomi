#!/usr/bin/env bats

load test_helper

@test "network dvs backing" {
  env=$(vcsim_env)
  if [ -z "$env" ]
  then
    skip "requires vcsim"
  fi
  export $env

  # DVS backed network by default (from vcsim_env)
  vm=$(new_empty_vm)

  eth0=$(govc device.ls -vm $vm | grep ethernet- | awk '{print $1}')
  run govc device.info -vm $vm $eth0
  assert_success

  summary=$(govc device.info -vm $vm $eth0 | grep Summary: | awk '{print $2}')
  assert_equal "DVSwitch:" $summary

  # TODO: vm.network.remove does not work with DVS
  run govc device.remove -vm $vm $eth0
  assert_success

  eth0=$(govc device.ls -vm $vm | grep ethernet- | awk '{print $1}')
  [ -n "$eth0"]

  # Standard network backing
  run govc vm.network.add -vm $vm -net "VM Network"
  assert_success

  eth0=$(govc device.ls -vm $vm | grep ethernet- | awk '{print $1}')

  run govc device.info -vm $vm $eth0
  assert_success

  summary=$(govc device.info -vm $vm $eth0 | grep Summary: | awk -F: '{print $2}')
  assert_equal "VM Network" $(collapse_ws $summary)
}

@test "network standard backing" {
  vm=$(new_empty_vm)

  run govc device.info -vm $vm ethernet-0
  assert_success

  run govc vm.network.remove -vm $vm
  assert_failure "Error: please specify a network"

  run govc vm.network.remove -vm $vm "VM Network"
  assert_success

  run govc device.info -vm $vm ethernet-0
  assert_failure

  run govc vm.network.add -vm $vm enoent
  assert_failure "Error: no such network"

  run govc vm.network.add -vm $vm "VM Network"
  assert_success

  run govc device.info -vm $vm ethernet-0
  assert_success
}
