using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/*
spline class
multispline
- endpoints and creates mid points for flow, makes tangents line up and add variations

mesh generates cylinder and updatespoint based on cylinder location + spline location into sin
click to generate, update spline flow and destroy 
pastel colors + dynamic colors also based on two controls + angle, (whhich makes three)
also drive 



all this shit in vertex + fragment shaders
*/

public class Shooter : MonoBehaviour
{

    public GameObject ballPrefab, cylinderPrefab;
    
    //List<Vector3[]> pointsList = new();
    //List<GameObject[]> ballList = new();

    List<GameObject> cylinders = new();
    List<Material> cylinderMaterials = new();
    
    [SerializeField] float shotLength = 15.0f;
    [SerializeField] float incSpeed = 0.17f;
    [SerializeField] float incDiff = 0.95f;
    [SerializeField] float gather = 20f;
    [SerializeField] int numSplines = 8     ;

    List<float> incs = new List<float>();
    // Start is called before the first frame update
    List<GameObject> instances = new();
    void Shoot()
    {

        var start = transform.position + (Random.value-0.5f)*transform.right*4f;
        var end = transform.position + shotLength*transform.forward;


        
        var points = new Vector3[numSplines*3+1];

        // endpoints
        points[0] = start;
        points[points.Length-1] = end;
        for (var i = 0; i < numSplines; i++) {
            points[i*3+3] = Vector3.Lerp(start, end, ((float) i/(numSplines+1))) + (Quaternion.Euler(0, 0, Random.value*360.0f) * Vector3.up * shotLength/gather);
        }

        // control
        for (var i = 0; i < numSplines; i++) {
            var d = (points[i*3+3]-points[i*3])/2;

            if (i == 0) {
                points[i*3+1] = start + d;//Vector3.Lerp(start, end, ((float) i/(numSplines+1)));     
            } else {
                points[i*3+1] = 2*points[i*3] - points[i*3-1];
            }
            points[i*3+2] = (points[i*3+3] - d) + (Quaternion.Euler(0, 0, Random.value*360.0f) * Vector3.up * d.magnitude*1.6f);
        }

        GameObject cylinder;
        if (instances.Count > 0) {
            cylinder = instances[0];
            cylinder.active = true;
            instances.RemoveAt(0);
        } else {
            cylinder = GameObject.Instantiate(cylinderPrefab);
        }
        var material = cylinder.GetComponent<MeshRenderer>().material;

        var _points = new float[points.Length*3];
        for (var i = 0; i < points.Length; i++) {
            _points[i*3] = points[i].x;
            _points[i*3+1] = points[i].y;
            _points[i*3+2] = points[i].z;
        }

        material.SetInteger("_Type", (int) Mathf.Floor(Random.Range(0, 5)));
        material.SetFloatArray("_Points", _points);
        material.SetFloat("_NumPoints", points.Length);

        material.SetFloat("_Inc", 0f);
        material.SetFloat("_IncDiff", incDiff);

        cylinders.Add(cylinder); 
        cylinderMaterials.Add(material);
        incs.Add(0);

        /*GameObject[] balls = new GameObject[150];
        for (var i = 0; i < balls.Length; i++) {
            if (instances.Count > 0) {
                balls[i] = instances[0];
                instances.RemoveAt(0);
                balls[i].active = true;
            } else {
                balls[i] = GameObject.Instantiate(ballPrefab, start, Quaternion.identity);
            }
        }

        pointsList.Add(points);
        ballList.Add(balls);
        incs.Add(0);
        */
    }

    Vector3 bez(Vector3 a, Vector3 b, Vector3 c, Vector3 d, float t) => Vector3.Lerp(
        Vector3.Lerp(a,b,t),
        Vector3.Lerp(c,d,t),
        t
    );

    // Update is called once per frame
    void Update()
    {
        for (var i = 0; i < incs.Count; i++) {
            if (cylinders[i].active) continue;
            instances.Add(cylinders[i]);

            incs.RemoveAt(i);
            cylinders.RemoveAt(i);
            cylinderMaterials.RemoveAt(i);
            i--;
        }

        if (Input.GetMouseButton(0)) {
            for (var i = 0; i < Random.value*15; i++) Shoot();
        }

        /*for (var i = 0; i < incs.Count; i++) {
            var skip = false;
            foreach (var b in ballList[i]) {
                if (b) skip = true;
            }
            if (skip) continue;

            incs.RemoveAt(i);
            ballList.RemoveAt(i);
            pointsList.RemoveAt(i);
            i--;
        }*/

        foreach (var cylinder in cylinders) {
            var index = cylinders.IndexOf(cylinder);
            incs[index] += Time.deltaTime*incSpeed;
            var inc = incs[index];
            var material = cylinderMaterials[index];

            if (inc > 1f + incDiff) {
                cylinder.active = false;
            } else {
                material.SetFloat("_Inc", inc);
                /*float _inc = Mathf.Min(Mathf.Max(inc - incDiff * ((float) _i)/balls.Length, 0f), 0.999f);
                int i = (int) Mathf.Floor(_inc*numSplines);
                float off = (_inc*numSplines)%1;

                ball.transform.position = bez(
                    points[i*3], points[i*3+1], points[i*2], points[i*3+3], off
                );*/
            }


        }

        /*foreach (var balls in ballList) {
            var index = ballList.IndexOf(balls);
            incs[index] += Time.deltaTime*incSpeed;
            var inc = incs[index];
            var points = pointsList[index];

            for (var _i = 0; _i < balls.Length; _i++) {
                var ball = balls[_i];
                if (ball) {
                    if (inc > 1f + incDiff) {
                        instances.Add(ball);
                        ball.active = false;
                        balls[_i] = null;
                    } else {
                        float _inc = Mathf.Min(Mathf.Max(inc - incDiff * ((float) _i)/balls.Length, 0f), 0.999f);
                        int i = (int) Mathf.Floor(_inc*numSplines);
                        float off = (_inc*numSplines)%1;

                        ball.transform.position = bez(
                            points[i*3], points[i*3+1], points[i*2], points[i*3+3], off
                        );
                    }
                }
            }
        }
        */

    }
}
