# metrics.py
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
import time

# Pushgateway 주소 (확인된 서비스 이름: my-pushgateway-prometheus-pushgateway)
PUSHGATEWAY_URL = 'my-pushgateway-prometheus-pushgateway.monitoring.svc:9091'

def push_job_metrics(job_name, success: bool, duration: float):
    """
    작업 결과를 Prometheus Pushgateway로 전송하는 함수
    작업 성공 여부와 소요 시간을 측정하여 모니터링 시스템으로 보냅니다.
    """
    try:
        registry = CollectorRegistry()
        
        # 성공 여부 게이지 생성 (1: 성공, 0: 실패)
        g_status = Gauge('jpx_collector_success', 'Job success status', registry=registry)
        g_status.set(1 if success else 0)
        
        # 작업 소요 시간 게이지 생성
        g_duration = Gauge('jpx_collector_duration_seconds', 'Job duration', registry=registry)
        g_duration.set(duration)
        
        # Pushgateway로 메트릭 전송
        push_to_gateway(PUSHGATEWAY_URL, job=job_name, registry=registry)
        
        # 전송 후 데이터 전송 시간을 고려하여 짧은 대기 후 로그 출력
        time.sleep(0.5)
        print(f"✅ [모니터링] 메트릭 전송 완료 (Job: {job_name}, Success: {success})", flush=True)
        
    except Exception as e:
        # 전송 실패 시 에러 내용을 출력 (실패 시에도 로그가 즉시 기록되도록 flush=True)
        print(f"⚠️ [모니터링] 메트릭 전송 실패: {e}", flush=True)