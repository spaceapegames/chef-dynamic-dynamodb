=======
chef-dynamic-dynamodb
=====================

this is a draft, and work in progress, will support single instance of dynamic dynamo, configuration will be pulled in from the databag.

Accepting pull requests actively, just create an issue and make a request, or catch me on irc (freenode willejs), twitter or email.

====
databag config
====

    {
      "test_1": {
        "decrease_reads_with": 50,
        "min_provisioned_reads": 100,
        "maintenance_windows": "22:00_23:59,00:00_06:00",
        "writes_lower_threshold": 30,
        "allow_scaling_down_reads_on_0_percent": true,
        "writes_upper_threshold": 90,
        "increase_reads_with": 50,
        "increase_reads_unit": "percent",
        "decrease_writes_with": 50,
        "max_provisioned_reads": 500,
        "always_decrease_rw_together": true,
        "reads_upper_threshold": 90,
        "allow_scaling_down_writes_on_0_percent": true,
        "reads_lower_threshold": 30,
        "decrease_writes_unit": "percent",
        "max_provisioned_writes": 500,
        "decrease_reads_unit": "percent",
        "increase_writes_with": 50,
        "min_provisioned_writes": 100,
        "increase_writes_unit": "percent"
      },
      "id": "tables"
    }
