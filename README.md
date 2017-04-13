This is a Graphite HA server example on vagrant.
==========================================================================

# Features
	clustered graphite
	
	graphite intake siteA 
	       |
	  HA proxy : 2003/2004 -    
	  |	              |
	 2213/2214      2313/2314   2003/2004 ports across 2 instances of level 2 HA proxies
	  relay1           relay2   
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

# Execution
```
	vagrant up
	#vagrant destroy -f && vagrant up
```

# Run
```
	http://192.168.82.170:8080
```