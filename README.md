# Kubeadm-installation

## 安裝環境
- ubuntu 18.04

## 特殊情況

💡 如果重開機有問題，操作完需要等一下

```
sudo swapoff -a
sudo strace -eopenat kubectl version

OR

sudo systemctl restart docker
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```


💡 如果忘記Master 的 join token

```
kubeadm token generate
kubeadm token create <generation_token> --print-join-command --ttl=0
```


# Master & worker node 都需要做一遍
## 更新與安裝
```
sudo apt update
sudo apt upgrade
sudo apt install vim net-tools -y
```


## 網路設定

1. 查看master and node的IP，互相ping看看是否有通
    
    ```
    ifconfig
    ping <node_IP>
    ```
    
    ![https://i.imgur.com/5WCsetH.png](https://i.imgur.com/5WCsetH.png)
    
2. 設定hostname (可取名worker node1、master之類的，方便後面辨識)
    
    ```
    sudo hostnamectl set-hostname <name>
    ```
    
3. 編輯hosts檔案
    
    ```
    sudo vim /etc/hosts
    ```
    
    ![https://i.imgur.com/shNoeW9.png](https://i.imgur.com/shNoeW9.png)
    
4. 安裝docker，查看version
    
    ```
    sudo apt-get install docker.io -y
    sudo docker version
    ```
    
    ![https://i.imgur.com/wlNQoBw.png](https://i.imgur.com/wlNQoBw.png)
    
5. 啟動docker並查看狀態
    
    ```
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo systemctl status docker
    ```
    
    ![https://i.imgur.com/4Mf46jj.png](https://i.imgur.com/4Mf46jj.png)
    
6. 關閉swap
    
    ```
    sudo swapoff -a
    top
    ```
    
    ![https://i.imgur.com/rwgFKJd.png](https://i.imgur.com/rwgFKJd.png)
    

## 安裝kubeadm、kubelet 和 kubectl

```
sudo apt-get update && sudo apt-get install -y apt-transport-https curl vim
```

```docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

OR

# sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
```

```docker
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

OR

# echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

```docker
sudo apt-get update
```

## 安裝 kubelet、kubeadm、kubectl

```sh
# 安裝最新版本
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

OR

# 指定安裝版本
## 找到可用的版本 
apt-cache madison kubeadm

## 指定版本
K_VER="<version>"
## ex : K_VER="1.21.3-00"

sudo apt-get install -y kubelet=${K_VER} kubectl=${K_VER} kubeadm=${K_VER}
```


## 修改docker文件

[Reference](https://blog.csdn.net/M82_A1/article/details/97626309)

1. /etc/docker裡面創一個 daemon.json
    ```
    sudo vim /etc/docker/daemon.json
    ```

2. 加入這段
    ```
    {
    "exec-opts":["native.cgroupdriver=systemd"]
    }
    ```

3. 重啟docker
    ```
    sudo systemctl restart docker
    sudo systemctl status docker
    ```

</aside>

# Master端

1. 初始化master端的參數，這段主要是設定kubernetes後面一些元件可以使用的IP範圍，要注意最後有沒有出現warning
    ```sh
    # 跳過這段
    # export KUBECONFIG=/etc/kubernetes/admin.conf
    # sudo systemctl daemon-reload
    # sudo systemctl restart kubelet

    sudo kubeadm init   --pod-network-cidr=10.244.0.0/16 --service-cidr=10.245.0.0/16 --apiserver-advertise-address=<master_IP>
    ```

2. 最後應該會出現successfully的提示，還有後面的指令kubeadm join…要記錄起來，之後worker node才能透過那個token加入叢集中

3. 查看節點
    ```
    sudo systemctl status kubelet
    sudo kubectl get nodes
    ```

    - 如果出現“The connection to the server localhost:8080 was refused - did you specify the right host or port?”用下面這串，沒出現可以跳過

        ```
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
        ```

4. 這邊選擇flannel 也可以選擇其他的網路附加元件

    ```
    sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    ```

5. 需要等待一段時間(3-5 mins)，查看node列表

    ```
    sudo kubectl get nodes
    ```

    - 如果一直顯示"Not Ready"，執行下面那行後重制，直接重做[Master](https://github.com/z416352/Kubeadm-installation#master端)的部分

        ```
        sudo kubeadm reset
        ```

6. 把先前master複製的指令“kubeadm join  –token…..”在worker node執行

    ```
    kubeadm join <master_IP:6443> --token.....
    ```

7. master端執行，看有沒有出現node的資訊

    ```
    sudo kubectl get nodes
    ```

8. 檢查componentstatuses狀態

    ```
    sudo kubectl get cs
    ```

    - 如果出現Unhealthy，到/etc/kubernetes/manifests，將kube-controller-manager.yaml和kube-scheduler.yaml中的 –port=0 註解後重新用執行

        ```
        sudo systemctl restart kubelet
        ```

## Metrics Server

```bash
- --kubelet-preferred-address-types=InternalIP
- --kubelet-insecure-tls

https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
```
