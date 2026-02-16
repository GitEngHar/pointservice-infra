# Hi There 👋

## System Architecture
TBD

## Deploy process
TBD

## 🚀 Exec

- point add & user create
```shell
$ curl -X PUT http://test-lb-tf-1364297332.ap-northeast-1.elb.amazonaws.com:1323/point/add -H "Content-Type: application/json" -d '{"user_id": "a123b", "point_num": 100}'
{"messages":["point updated"]}
```


- point sub
```shell
$ curl -X PUT http://test-lb-tf-1364297332.ap-northeast-1.elb.amazonaws.com:1323/point/sub -H "Content-Type: application/json" -d '{"user_id": "a123b", "point_num": 10}'
{"messages":["point subtracted"]}
```


- point confirm 
```shell
$ curl -X GET http://test-lb-tf-1364297332.ap-northeast-1.elb.amazonaws.com:1323/point/confirm -H "Content-Type: application/json" -d '{"user_id": "a123b"}'
{"messages":["userID: a123b","pointNum: 90"]}
```

- health check
```shell
$ curl -X GET http://test-lb-tf-1364297332.ap-northeast-1.elb.amazonaws.com:1323/
{"messages":["ok"]}

$ curl -X GET http://test-lb-tf-1364297332.ap-northeast-1.elb.amazonaws.com:1323/health
{"messages":["ok"]}

$ curl -X GET http://test-lb-tf-1364297332.ap-northeast-1.elb.amazonaws.com:1323/health/
{"messages":["ok"]}
```