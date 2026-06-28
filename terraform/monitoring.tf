resource "helm_release" "kube_prometheus_stack" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  # 필요한 설정이 있다면 values.yaml을 별도로 만들어 참조
  values = [
    file("${path.module}/values/prometheus-values.yaml")
  ]
}