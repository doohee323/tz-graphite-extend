This project configure one side of HA installation of a clustered graphite

graphiteintake siteA   ---> intake point running HA proxy bgp to geo site B (same config)
       |
  HA proxy : 2003/2004 -    site level HA/loadbalancing may duplicate traffic across 2 geo systems
  |	              |
 2213/2214      2313/2314   forwards 2003/2004 ports across 2 instances of level 2 HA proxies
  relay1           relay2   which will cross forward to carbon instances using consistent hashing to
  |  \			  /  |      4 carbon cache instances
  r1  r2         r2  r1     
  |   \          /   |
 2413  2414     2513 2515
  |     |        |   |
  c1    c2      c2   c1  
     carbon cluster         whisper databases     
  |     |        |   |
  --------------------
            |
        memcache
            |
     web1:80 web2:80          web/api layer
            |
            HA:80
optional authentication layer 
implement your favorite flavor
