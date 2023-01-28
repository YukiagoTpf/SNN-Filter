using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode] // 让编辑器在不运行状态下运行
public class SNN : ScriptableRendererFeature
{
    [System.Serializable]   // renderfeature 的面板
    public class featureSetting
    {
        public string passRenderName = "SNN";
        public Material passMat;
        [Range(0, 10)] public float halfWidth = 0.5f;
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;
    }
    public featureSetting setting = new featureSetting();  // 实例化
    class SNNRenderFeature : ScriptableRenderPass
    {
        public Material passMat = null;
        public string passName;
        public float HalfWidth = 4;
        public float lerp = 1;
        string passTag = "SNN"; 
        private RenderTargetIdentifier passSource { get; set; } 

        public void setup(RenderTargetIdentifier sour) 
        {
            this.passSource = sour;
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            int TempID1 = Shader.PropertyToID("Temp1");
            int Halfwidth = Shader.PropertyToID("_half_width");
            int ScoureID = Shader.PropertyToID("_SourceTex");
            CommandBuffer cmd = CommandBufferPool.Get(passTag); 
            RenderTextureDescriptor getCameraData = renderingData.cameraData.cameraTargetDescriptor;   
            
            cmd.GetTemporaryRT(TempID1, getCameraData); 
            cmd.GetTemporaryRT(ScoureID, getCameraData);
            RenderTargetIdentifier Temp1 = TempID1;
            RenderTargetIdentifier Scoure = ScoureID;
            cmd.SetGlobalFloat(Halfwidth,HalfWidth);
            cmd.Blit(passSource, Scoure);
            cmd.ReleaseTemporaryRT(ScoureID); 
            cmd.Blit(passSource, Temp1, passMat, -1);  
            cmd.Blit(Temp1, passSource);            

            cmd.ReleaseTemporaryRT(TempID1);
            context.ExecuteCommandBuffer(cmd); 
            CommandBufferPool.Release(cmd); 
        }
    }
    SNNRenderFeature m_ScriptablePass;
    public override void Create()
    {
        m_ScriptablePass = new SNNRenderFeature();
        m_ScriptablePass.renderPassEvent = setting.passEvent;   
        m_ScriptablePass.passMat = setting.passMat;             
        m_ScriptablePass.passName = setting.passRenderName;    

        m_ScriptablePass.HalfWidth = setting.halfWidth;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScriptablePass.setup(renderer.cameraColorTarget);     
        renderer.EnqueuePass(m_ScriptablePass);                 
    }
}