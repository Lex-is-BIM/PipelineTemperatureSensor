local params = Style.GetParameterValues().General
local mounting = params.MountingOptions
local rPipe=params.PipeDiameter/2
local rBush = 11.5
local rod = params.MovableRod
local matrix = Matrix3D()
local matrixBody = Matrix3D()
local plac = Placement3D(Point3D(0,0,0),Vector3D(0,0,1),Vector3D(1,0,0))
local outPlac = Placement3D(Point3D(-36,0,33),Vector3D(-1,0,0),Vector3D(0,0,-1))

local l
local lRod=0

function pipePlac(v)
   return Placement3D(Point3D(0,0,0),Vector3D(1*v,0,0),Vector3D(-1*v,0,0))
end

function circ(r)
    return CreateCircle2D(Point2D(0,0),r)
end

function nut(e,m)
    local point = Point2D(0,e/2)
    local points = {}
    for i=0,6 do
        table.insert(points, point:Clone():Rotate(Point2D(0,0),math.pi/3*i) )
    end
    return Unite(Extrude(CreatePolyline2D(points),ExtrusionParameters(m)),
        CreateRightCircularCylinder(7,40))
end

lRod = rod and 40 or 0

if mounting == "Direct" then
        l = math.cos(math.asin(rBush/rPipe))*rPipe+40
        matrix:Shift(0,0,l)
        matrixBody:Shift(0,0,l+lRod)
    else
        l = (rPipe-rBush*math.sin(math.pi/4))/math.cos(math.pi/4)+40
        matrix:Shift(0,0,l):Rotate(CreateYAxis3D(),math.pi/4)
        matrixBody:Shift(0,0,l+lRod):Rotate(CreateYAxis3D(),math.pi/4)
end

local bodyPlac = Placement3D(Point3D(0,0,10),Vector3D(0,0,1),Vector3D(1,0,0))
local topPlac = Placement3D(Point3D(0,0,10),Vector3D(0,0,1),Vector3D(1,0,0))
    :Rotate(CreateYAxis3D(),math.rad(20)):Shift(-2.51,0,29)

local bushing = Subtract(Extrude(circ(rBush),ExtrusionParameters(0,l),plac)
    :Transform(matrix),
    CreateRightCircularCylinder(rPipe,rPipe*6):Shift(0,0,-rPipe*3)
    :Rotate(CreateYAxis3D(),math.pi/2))

bushing = rod and Unite(bushing,nut(26,15):Transform(matrix)) or bushing

local top = Unite({
    CreateRightCircularCylinder(29,6),
    CreateRightCircularCylinder(27,8):Shift(0,0,6),
    Loft({circ(25),circ(10)},{plac:Clone():Shift(0,0,14),plac:Clone():Shift(0,0,22)}),
    CreateRightCircularCylinder(10,5):Shift(0,0,22)
}) 

local body = Unite({
    Loft({circ(18),CreateEllipse2D(Point2D(0,0),0,27.42,25.7)},{bodyPlac,topPlac}),
    top:Transform(topPlac:GetMatrix()),
    CreateRightCircularCylinder(12,10),
    Extrude(circ(10),ExtrusionParameters(0,20),outPlac)    
})

body = Unite(body:Transform(matrixBody),bushing)

Style.SetDetailedGeometry(ModelGeometry():AddSolid(body))

function symb(r,rPipe)
    local symb = GeometrySet2D()
    local contour = CreateCircle2D(Point2D(0,r*3+rPipe),r)
    symb:AddCurve(contour)
    symb:AddMaterialColorSolidArea(FillArea(contour))
    symb:AddCurve(CreateLineSegment2D(Point2D(0,0),Point2D(0,r*2+rPipe)))
    symb:AddCurve(CreateLineSegment2D(Point2D(0,r*2.5+rPipe),Point2D(0,r*3.5+rPipe)))
    symb:AddCurve(CreateLineSegment2D(Point2D(-r*0.4,r*3.5+rPipe),Point2D(r*0.4,r*3.5+rPipe)))
    return symb
end

Style.SetSymbolGeometry(ModelGeometry():AddGeometrySet2D(symb(2.5,0)))
Style.SetSymbolicGeometry(ModelGeometry():AddGeometrySet2D(symb(100,rPipe)))
Style.GetPort("PipeInlet"):SetPlacement(pipePlac(-1))
Style.GetPort("PipeOutlet"):SetPlacement(pipePlac(1))
Style.GetPort("ElectricPort"):SetPlacement(outPlac:Transform(matrixBody))
