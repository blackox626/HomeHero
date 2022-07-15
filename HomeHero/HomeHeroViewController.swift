/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import ARKit

enum FunctionMode {
  case none
  case placeObject(String)
  case measure
}

class HomeHeroViewController: UIViewController {
  
  @IBOutlet var sceneView: ARSCNView!
  @IBOutlet weak var chairButton: UIButton!
  @IBOutlet weak var candleButton: UIButton!
  @IBOutlet weak var measureButton: UIButton!
  @IBOutlet weak var vaseButton: UIButton!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var crosshair: UIView!
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var trackingInfo: UILabel!
  
  var currentMode: FunctionMode = .none
  var objects: [SCNNode] = []
  var measuringNodes: [SCNNode] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    runSession()
    trackingInfo.text = ""
    messageLabel.text = ""
    distanceLabel.isHidden = true
    selectVase()
  }
  
  @IBAction func didTapChair(_ sender: Any) {
    currentMode = .placeObject("Models.scnassets/chair/chair.scn")
    selectButton(chairButton)
  }
  
  @IBAction func didTapCandle(_ sender: Any) {
    currentMode = .placeObject("Models.scnassets/candle/candle.scn")
    selectButton(candleButton)
  }
  
  @IBAction func didTapMeasure(_ sender: Any) {
    currentMode = .measure
    selectButton(measureButton)
  }
  
  @IBAction func didTapVase(_ sender: Any) {
    selectVase()
  }
  
  @IBAction func didTapReset(_ sender: Any) {
    removeAllObjects()
    distanceLabel.text = ""
  }
  
  func selectVase() {
    currentMode = .placeObject("Models.scnassets/vase/vase.scn")
    selectButton(vaseButton)
  }
  
  func selectButton(_ button: UIButton) {
    unselectAllButtons()
    button.isSelected = true
  }
  
  func unselectAllButtons() {
    [chairButton, candleButton, measureButton, vaseButton].forEach {
      $0?.isSelected = false
    }
  }
  
  func removeAllObjects() {
    for object in objects {
      object.removeFromParentNode()
    }
    
    objects = []
  }
  
  func runSession() {
    // 1
    sceneView.delegate = self
    // 2
    let configuration = ARWorldTrackingConfiguration()
    // 3
    configuration.planeDetection = .horizontal
    // 4
    configuration.isLightEstimationEnabled = true
    // 5
    sceneView.session.run(configuration)
    // 6
    #if DEBUG
    sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
    #endif
  }
  
  override func touchesBegan(_ touches: Set<UITouch>,
                             // 1
    with event: UIEvent?) {
    if let hit = sceneView.hitTest(
      viewCenter,
      types: [.existingPlaneUsingExtent]).first {
      sceneView.session.add(
        anchor: ARAnchor(transform: hit.worldTransform))
      return
    } else if let hit = sceneView.hitTest(
      viewCenter,
      types: [.featurePoint]).last {
      sceneView.session.add(
        anchor: ARAnchor(transform: hit.worldTransform))
      return
    }
    
  }
  
  func measure(fromNode: SCNNode, toNode: SCNNode) {
    // 1
    let measuringLineNode = createLineNode(
      fromNode: fromNode,
      toNode: toNode)
    // 2
    measuringLineNode.name = "MeasuringLine"
    // 3
    sceneView.scene.rootNode.addChildNode(measuringLineNode)
    objects.append(measuringLineNode)
    // 4
    let dist = fromNode.position.distanceTo(toNode.position)
    let measurementValue = String(format: "%.2f", dist)
    // 5
    distanceLabel.text = "Distance: \(measurementValue) m"
  }
  
  func updateMeasuringNodes() {
    guard measuringNodes.count > 1 else {
      return
    }
    let firstNode = measuringNodes[0]
    let secondNode = measuringNodes[1]
    // 1
    let showMeasuring = self.measuringNodes.count == 2
    distanceLabel.isHidden = !showMeasuring
    if showMeasuring {
      measure(fromNode: firstNode, toNode: secondNode)
    } else if measuringNodes.count > 2  {
      // 2
      firstNode.removeFromParentNode()
      secondNode.removeFromParentNode()
      measuringNodes.removeFirst(2)
      // 3
      for node in sceneView.scene.rootNode.childNodes {
        if node.name == "MeasuringLine" {
          node.removeFromParentNode()
        }
      } }
  }
  
  func updateTrackingInfo() {
    // 1
    guard let frame = sceneView.session.currentFrame else {
      return
    }
    // 2
    switch frame.camera.trackingState {
    case .limited(let reason):
      switch reason {
      case .excessiveMotion:
        trackingInfo.text = "Limited Tracking: Excessive Motion"
      case .insufficientFeatures:
        trackingInfo.text =
        "Limited Tracking: Insufficient Details"
      default:
        trackingInfo.text = "Limited Tracking"
      }
    default:
      trackingInfo.text = ""
    }
    // 3
    guard
      let lightEstimate = frame.lightEstimate?.ambientIntensity
      else {
        return
    }
    // 4
    if lightEstimate < 100 {
      trackingInfo.text = "Limited Tracking: Too Dark"
    }
  }
  
  
  
}

extension HomeHeroViewController: ARSCNViewDelegate {
  
//  func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//
//      if let planeAnchor = anchor as? ARPlaneAnchor {
//
//        let planeNode = createPlaneNode(
//          center: planeAnchor.center,
//          extent: planeAnchor.extent)
//
//        let node = SCNNode();
//        node.addChildNode(planeNode);
//        return node;
//
//      }
//
//      return nil;
//
//  }
  
  
  /// self.sceneview.scene.rootnode 跟参数 node 都是代表一个坐标系 只有（position rotation scale）
  /// 需要通过添加 childnode （camera light geometry 等等） 才能在scene中显示出来
  /// SCNNode
  /// A structural element of a scene graph, representing a position and transform in a 3D coordinate space, to which you can attach geometry, lights, cameras, or other displayable content.
  
//   1
  func renderer(_ renderer: SCNSceneRenderer,
                didAdd node: SCNNode,
                for anchor: ARAnchor) {
    DispatchQueue.main.async {
      if let planeAnchor = anchor as? ARPlaneAnchor {
        #if DEBUG
        let planeNode = createPlaneNode(
          center: planeAnchor.center,
          extent: planeAnchor.extent)
        node.addChildNode(planeNode)
        
        print("createPlaneNode");
        
        #endif
      } else {
        switch self.currentMode {
        case .none:
          break
        case .placeObject(let name):
          let modelClone = nodeWithModelName(name)
          self.objects.append(modelClone)
          modelClone.position = SCNVector3Zero
          node.addChildNode(modelClone)
        case .measure:
          // 1
          let sphereNode = createSphereNode(radius: 0.02)
          // 2
          self.objects.append(sphereNode)
          // 3
          node.addChildNode(sphereNode)
          // 4
          self.measuringNodes.append(node)
        }
      } }
  }
  
  func renderer(_ renderer: SCNSceneRenderer,
                didUpdate node: SCNNode,
                for anchor: ARAnchor) {
    DispatchQueue.main.async {
      if let planeAnchor = anchor as? ARPlaneAnchor {
        updatePlaneNode(node.childNodes[0],center: planeAnchor.center,
                        extent: planeAnchor.extent)
      } else {
        self.updateMeasuringNodes()
      }
    }
    
  }
  
  func renderer(_ renderer: SCNSceneRenderer,
                didRemove node: SCNNode,
                for anchor: ARAnchor) {
    guard anchor is ARPlaneAnchor else { return }
    // 2
    removeChildren(inNode: node)
  }
  
  func renderer(_ renderer: SCNSceneRenderer,
                updateAtTime time: TimeInterval) {
    DispatchQueue.main.async {
      // 1
      self.updateTrackingInfo()
      // 2
      if let _ = self.sceneView.hitTest(
        self.viewCenter,
        types: [.existingPlaneUsingExtent]).first {
        self.crosshair.backgroundColor = UIColor.green
      } else {
        self.crosshair.backgroundColor = UIColor(white: 0.34,alpha: 1)
      }
      
    }
  }
  
  func session(_ session: ARSession,
    didFailWithError error: Error) {
    showMessage(error.localizedDescription,
                label: messageLabel,
                seconds: 2)
  }
  
  func sessionWasInterrupted(_ session: ARSession) {
    showMessage("Session interrupted",label: messageLabel,
                seconds: 2)
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    showMessage("Session resumed",
                label: messageLabel,
                seconds: 2)
    // 3
    removeAllObjects()
    runSession()
  }
  
}
