# redis 集群安装

##规划

3 master 3 slave 均在一台centos机器上

使用dev/sdd1 盘  1.7T作为redis的 数据存储位置，并mount到/data/redis文件夹

redis 采用 redis-5.0.0版本。 

### 下载并解压 

```
wget 
tar -xvf 
```

## 编译安装 

```
cd redis-3.2.4
make && make install
```

## 修改配置文件

创建 Redis 节点 

```
mkdir /etc/redis/cluster　
```

将github上  复制到此处

修改配置文文/cfg/8700.conf cfg/8701.conf  cfg/8702.conf  cfg/8703.conf  cfg/8704.conf  cfg/8705.conf 

```
port 8700
pidfile /var/run/redis_8700.pid
dir /data/redis/8700
appendfilename "appendonly_8700.aof
cluster-announce-ip 192.168.3.39
cluster-announce-port 8700
cluster-announce-bus-port 18700
```

对应的修改其他的配置文件

修改完成后在/data/redis/创建 8700 8701 8702 8703 8704 8705 文件夹

```
mkdir -p /data/redis/8700
mkdir -p /data/redis/8701
mkdir -p /data/redis/8702
mkdir -p /data/redis/8703
mkdir -p /data/redis/8704
mkdir -p /data/redis/8705
```

 ## 启动各个节点

```
redis-server redis_cluster/8700/redis.conf
redis-server redis_cluster/8701/redis.conf
redis-server redis_cluster/8702/redis.conf
redis-server redis_cluster/8703/redis.conf
redis-server redis_cluster/8704/redis.conf
redis-server redis_cluster/8705/redis.conf
```

或者直接运行

```
/etc/redis/cluster/start.sh
```

这个时候查看是否都启动了

```
netstat -nlput | grep redis
```

```
[root@oceanatlantic cluster]# netstat -nlput | grep redis
tcp        0      0 0.0.0.0:18700           0.0.0.0:*               LISTEN      324281/redis-server 
tcp        0      0 0.0.0.0:18701           0.0.0.0:*               LISTEN      324446/redis-server 
tcp        0      0 0.0.0.0:18702           0.0.0.0:*               LISTEN      324471/redis-server 
tcp        0      0 0.0.0.0:18703           0.0.0.0:*               LISTEN      324483/redis-server 
tcp        0      0 0.0.0.0:18704           0.0.0.0:*               LISTEN      324490/redis-server 
tcp        0      0 0.0.0.0:18705           0.0.0.0:*               LISTEN      324499/redis-server 
tcp        0      0 0.0.0.0:8700            0.0.0.0:*               LISTEN      324281/redis-server 
tcp        0      0 0.0.0.0:8701            0.0.0.0:*               LISTEN      324446/redis-server 
tcp        0      0 0.0.0.0:8702            0.0.0.0:*               LISTEN      324471/redis-server 
tcp        0      0 0.0.0.0:8703            0.0.0.0:*               LISTEN      324483/redis-server 
tcp        0      0 0.0.0.0:8704            0.0.0.0:*               LISTEN      324490/redis-server 
tcp        0      0 0.0.0.0:8705            0.0.0.0:*               LISTEN      324499/redis-server 
tcp6       0      0 :::18700                :::*                    LISTEN      324281/redis-server 
tcp6       0      0 :::18701                :::*                    LISTEN      324446/redis-server 
tcp6       0      0 :::18702                :::*                    LISTEN      324471/redis-server 
tcp6       0      0 :::18703                :::*                    LISTEN      324483/redis-server 
tcp6       0      0 :::18704                :::*                    LISTEN      324490/redis-server 
tcp6       0      0 :::18705                :::*                    LISTEN      324499/redis-server 
tcp6       0      0 :::8700                 :::*                    LISTEN      324281/redis-server 
tcp6       0      0 :::8701                 :::*                    LISTEN      324446/redis-server 
tcp6       0      0 :::8702                 :::*                    LISTEN      324471/redis-server 
tcp6       0      0 :::8703                 :::*                    LISTEN      324483/redis-server 
tcp6       0      0 :::8704                 :::*                    LISTEN      324490/redis-server 
tcp6       0      0 :::8705                 :::*                    LISTEN      324499/redis-server 
```

## 创建集群 

```
redis-cli --cluster create 192.168.3.39:8700 192.168.3.39:8701 192.168.3.39:8702 192.168.3.39:8703 192.168.3.39:8704 192.168.3.39:8705 --cluster-replicas 1 -a 123123
```

会出现一个提示， `can i set the above configuration?` 输入yes即可

检查集群

```
redis-cli --cluster check 192.168.3.9:8700 -a xxx
```

集群验证 

```
redis-cli -h 192.168.3.9 -c -p 8700 -a xxx   # -c是进入集群
[root@oceanatlantic cluster]# redis-cli -h 192.168.3.9 -c -p 8700 
192.168.3.39:8700> AURTH
(error) ERR unknown command `AURTH`, with args beginning with: 
192.168.3.39:8700> auth xxx
OK
192.168.3.39:8700> cluster info
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:6
cluster_my_epoch:1
cluster_stats_messages_ping_sent:11482
cluster_stats_messages_pong_sent:11720
cluster_stats_messages_sent:23202
cluster_stats_messages_ping_received:11715
cluster_stats_messages_pong_received:11482
cluster_stats_messages_meet_received:5
cluster_stats_messages_received:23202
192.168.3.39:8700> 
#可以看到集群信息，然后再8700上set一个 key value
192.168.3.39:8700> set hello world
OK
192.168.3.39:8700> 
切换到8702端口
[root@oceanatlantic cluster]# redis-cli -h 192.168.3.39 -c -p 8703 -a xxx
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
192.168.3.39:8703> get hello
-> Redirected to slot [866] located at 192.168.3.39:8700
"world"
成功
```

简单说一下原理

redis cluster在设计的时候，就考虑到了去中心化，去中间件，也就是说，集群中的每个节点都是平等的关系，都是对等的，每个节点都保存各自的数据和整个集群的状态。每个节点都和其他所有节点连接，而且这些连接保持活跃，这样就保证了我们只需要连接集群中的任意一个节点，就可以获取到其他节点的数据。

Redis 集群没有并使用传统的一致性哈希来分配数据，而是采用另外一种叫做`哈希槽 (hash slot)`的方式来分配的。redis cluster 默认分配了 16384 个slot，当我们set一个key 时，会用`CRC16`算法来取模得到所属的`slot`，然后将这个key 分到哈希槽区间的节点上，具体算法就是：`CRC16(key) % 16384。所以我们在测试的时候看到set 和 get 的时候，直接跳转到了8700端口的节点。`

Redis 集群会把数据存在一个 master 节点，然后在这个 master 和其对应的salve 之间进行数据同步。当读取数据时，也根据一致性哈希算法到对应的 master 节点获取数据。只有当一个master 挂掉之后，才会启动一个对应的 salve 节点，充当 master 。

需要注意的是：必须要`3个或以上`的主节点，否则在创建集群时会失败，并且当存活的主节点数小于总节点数的一半时，整个集群就无法提供服务了。



 