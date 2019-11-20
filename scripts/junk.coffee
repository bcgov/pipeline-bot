
str = "docker-registry.default.svc:5000/databcdc/bcdc-test:latest"

re = new RegExp('\:latest$')
endPos = str.search(re)
if endPos != -1
    str2 = str.slice(0, endPos)
    console.log str2
    console.log str
